unit UnitMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Ani, FMX.Effects, FMX.Filter.Effects, System.UIConsts;

type
  TAnimatedPoint = record
    Position: TPointF;
    Angle: Single;
    constructor Create(X, Y, Angle: Single);
  end;

  TFormMain = class(TForm)
    PaintBox: TPaintBox;
    TimerAnimate: TTimer;
    procedure PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
    procedure FormCreate(Sender: TObject);
    procedure TimerAnimateTimer(Sender: TObject);
  private
    Points: TArray<TAnimatedPoint>;
    Bitmap: TBitmap;
    procedure Update();
  end;

const
  PointCount = 7;
  AnimationSpeed = 2.0;
  BorderWidth = 10.0;
  IterationCount = 4;
  DarkValue = 4;
  PathOpacity = 0.6;
  //PathColor = TAlphaColorRec.Lightcyan;//TAlphaColorRec.Bisque;

var
  FormMain: TFormMain;

implementation

{$R *.fmx}

{$POINTERMATH ON}
{$RANGECHECKS OFF}
{$OVERFLOWCHECKS OFF}
procedure DarkBitmap(Bitmap: TBitmap; Value: Byte);
var
  Data: TBitmapData;
  PixelLine: PAlphaColor;
  X, Y: Integer;
  Color: TAlphaColorRec;
begin
  Assert(Bitmap.Map(TMapAccess.ReadWrite, Data));
  try
    if Data.PixelFormat in [TPixelFormat.BGRA, TPixelFormat.RGBA] then
    begin
      for Y := 0 to Data.Height - 1 do
      begin
        PixelLine := Data.GetScanline(Y);
        for X := 0 to Data.Width - 1 do
        begin
          // read pixel
          Color.Color := PixelLine[X];
          // A
          Color.A := 255;
          // R
          if Color.R > Value then
            Color.R := Color.R - Value
          else
            Color.R := 0;
          // G
          if Color.G > Value then
            Color.G := Color.G - Value
          else
            Color.G := 0;
          // B
          if Color.B > Value then
            Color.B := Color.B - Value
          else
            Color.B := 0;
          // write pixel
          PixelLine[X] := Color.Color;
        end;
      end;
    end;
  finally
    Bitmap.Unmap(Data);
  end;
end;
{$POINTERMATH OFF}
{$RANGECHECKS ON}
{$OVERFLOWCHECKS ON}

function ChaikinPoints(Points: TArray<TPointF>): TArray<TPointF>;
var
  I: Integer;
begin
  Result := [];

  for I := 0 to High(Points) do
  begin
    Result := Result + [TPointF.Create(
      (Points[I].X * 0.75 + Points[(I + 1) mod Length(Points)].X * 0.25),
      (Points[I].Y * 0.75 + Points[(I + 1) mod Length(Points)].Y * 0.25)
    )];
    Result := Result + [TPointF.Create(
      (Points[I].X * 0.25 + Points[(I + 1) mod Length(Points)].X * 0.75),
      (Points[I].Y * 0.25 + Points[(I + 1) mod Length(Points)].Y * 0.75)
    )];
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  Bitmap := TBitmap.Create(800, 600);

  Points := [];
  for I := 0 to PointCount - 1 do
  begin
    Points := Points + [
      TAnimatedPoint.Create(Bitmap.Width * Random(), Bitmap.Height * Random(), 2 * Pi * Random())
    ];
  end;
end;

procedure TFormMain.Update();
var
  I: Integer;
  PathPoints: TArray<TPointF>;
  Path: TPathData;
begin
  // *** update ***

  // animate points
  for I := 0 to High(Points) do
  begin
    Points[I].Position.X := Points[I].Position.X + Cos(Points[I].Angle) * AnimationSpeed;
    Points[I].Position.Y := Points[I].Position.Y + Sin(Points[I].Angle) * AnimationSpeed;
  end;

  // fix out of bounds
  for I := 0 to High(Points) do
  begin
    // left
    if Points[I].Position.X < BorderWidth then
      Points[I].Angle := -Pi / 2 + Random * Pi;
    // right
    if Points[I].Position.X > Bitmap.Width - BorderWidth then
      Points[I].Angle := Pi / 2 + Random * Pi;
    // top
    if Points[I].Position.Y < BorderWidth then
      Points[I].Angle := Random * Pi;
    // bottom
    if Points[I].Position.Y > Bitmap.Height - BorderWidth then
      Points[I].Angle := Pi + Random * Pi;
  end;

  // *** make path from point ***

  // copy points
  PathPoints := [];
  for I := 0 to High(Points) do
    PathPoints := PathPoints + [Points[I].Position];

  // make path
  for I := 0 to IterationCount - 1 do
    PathPoints := ChaikinPoints(PathPoints);

  // *** draw to buffer ***

  // darker background
  DarkBitmap(Bitmap, DarkValue);

  // draw
  Bitmap.Canvas.BeginScene();
  try
    // make path
    Path := TPathData.Create();
    try
      // add points to path
      Path.MoveTo(PathPoints[0]);
      for I := 1 to High(PathPoints) do
        Path.LineTo(PathPoints[I]);
      Path.ClosePath();

      // draw
      Bitmap.Canvas.Stroke.Kind := TBrushKind.Solid;
      Bitmap.Canvas.Stroke.Color := HSLtoRGB((TThread.GetTickCount64() div 30 mod 360) / 360, 1.0, 0.8);// PathColor;
      Bitmap.Canvas.Stroke.Join := TStrokeJoin.Round;
      Bitmap.Canvas.Stroke.Thickness := 7;
      Bitmap.Canvas.DrawPath(Path, PathOpacity);
    finally
      Path.Free();
    end;
  finally
    Bitmap.Canvas.EndScene();
  end;
end;

procedure TFormMain.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
begin
  PaintBox.Canvas.DrawBitmap(Bitmap, Bitmap.BoundsF, Bitmap.BoundsF, 1);
end;

procedure TFormMain.TimerAnimateTimer(Sender: TObject);
begin
  Update();

  Invalidate();
end;

{ TAniPoint }

constructor TAnimatedPoint.Create(X, Y, Angle: Single);
begin
  Self.Position.X := X;
  Self.Position.Y := Y;
  Self.Angle := Angle;
end;

end.

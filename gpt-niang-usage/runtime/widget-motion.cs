using System;
using System.IO;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using WpfImage = System.Windows.Controls.Image;
using DrawingImage = System.Drawing.Image;

// Original GIF timing is retained. The timer redraws transforms, never inserts GIF frames.
public static class GptWidgetMotionMath {
    public static string SelectEgg(double roll, bool zero, bool enabled, bool squish, bool dance, bool boxing) {
        if (!enabled || Double.IsNaN(roll) || roll < 0 || roll >= .05) return null;
        int slot = Math.Min(zero ? 2 : 1, (int)Math.Floor(roll / .05 * (zero ? 3 : 2)));
        if (slot == 0) return squish ? "squish" : null;
        if (slot == 1) return dance ? "dance" : null;
        return boxing ? "zero" : null;
    }
    public static double Ease(double value) { value = Math.Max(0, Math.Min(1, value)); return 1 - Math.Pow(1 - value, 3); }
    public static double[] Stretch(double milliseconds) {
        double p = (milliseconds % 800) / 800;
        double[] at = {0, .30, .65, 1}, x = {1, 1.20, .85, 1}, y = {1, .75, 1.18, 1};
        int i = p < .30 ? 0 : p < .65 ? 1 : 2;
        double t = (p - at[i]) / (at[i+1] - at[i]); t = .5 - .5 * Math.Cos(t * Math.PI);
        return new[] { x[i] + (x[i+1]-x[i])*t, y[i] + (y[i+1]-y[i])*t };
    }
}

public sealed class GptWidgetGif : IDisposable {
    readonly MemoryStream stream;
    readonly DrawingImage image;
    public readonly int[] Delays;
    public readonly int Duration;
    public int FrameCount { get { return Delays.Length; } }
    public GptWidgetGif(string path) {
        var info = new FileInfo(path);
        if (info.Length < 6 || info.Length > 20 * 1024 * 1024) throw new InvalidDataException("GIF size is invalid.");
        stream = new MemoryStream(File.ReadAllBytes(path), false);
        try {
            image = DrawingImage.FromStream(stream, true, true);
            if (image.RawFormat.Guid != ImageFormat.Gif.Guid || image.Width > 2048 || image.Height > 2048) throw new InvalidDataException("GIF dimensions are invalid.");
            int count = image.GetFrameCount(FrameDimension.Time);
            if (count < 1 || count > 200) throw new InvalidDataException("GIF frame count is invalid.");
            byte[] timing = image.GetPropertyItem(0x5100).Value;
            if (timing.Length < count * 4) throw new InvalidDataException("GIF timing is missing.");
            Delays = new int[count];
            for (int i=0; i<count; i++) {
                long delay = (long)BitConverter.ToUInt32(timing, i*4)*10;
                if (delay < 20 || delay > 10000) throw new InvalidDataException("GIF timing is invalid.");
                Delays[i] = (int)delay; Duration += Delays[i];
            }
        } catch { if (image != null) image.Dispose(); stream.Dispose(); throw; }
    }
    public int FrameAt(double elapsed) {
        double at = elapsed % Duration;
        for (int i=0; i<Delays.Length; i++) { if (at < Delays[i]) return i; at -= Delays[i]; }
        return Delays.Length-1;
    }
    public BitmapSource Decode(int index) {
        if (index < 0 || index >= FrameCount) throw new ArgumentOutOfRangeException("index");
        image.SelectActiveFrame(FrameDimension.Time, index);
        double ratio = Math.Min(1, 640.0 / Math.Max(image.Width, image.Height));
        int width = Math.Max(1, (int)Math.Round(image.Width*ratio)), height = Math.Max(1, (int)Math.Round(image.Height*ratio));
        using (var canvas = new Bitmap(width, height, System.Drawing.Imaging.PixelFormat.Format32bppArgb)) {
            using (var g = Graphics.FromImage(canvas)) {
                g.Clear(System.Drawing.Color.Transparent);
                g.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
                g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                g.DrawImage(image, new Rectangle(0,0,width,height));
            }
            using (var png = new MemoryStream()) {
                canvas.Save(png, ImageFormat.Png); png.Position=0;
                var result = new BitmapImage(); result.BeginInit(); result.CacheOption=BitmapCacheOption.OnLoad; result.StreamSource=png; result.EndInit(); result.Freeze(); return result;
            }
        }
    }
    public void Dispose() { image.Dispose(); stream.Dispose(); }
}

public sealed class GptWidgetMotion : IDisposable {
    readonly WpfImage girl;
    readonly ScaleTransform press;
    readonly ScaleTransform stretch = new ScaleTransform(1,1);
    readonly TranslateTransform alignment = new TranslateTransform();
    readonly DispatcherTimer timer;
    readonly Stopwatch clock = Stopwatch.StartNew();
    BitmapSource normal, squishImage;
    GptWidgetGif gif;
    double pressAt=-1, releaseAt=-1, attack, rebound, fromX=1, fromY=1, eggAt;
    int lastFrame=-1, repeats=1, alphaWidth, alphaHeight;
    byte[] alpha;
    bool held, disposed;
    string kind;
    public double Speed = 1;
    public bool Immediate;
    public double AnimationPadding = 14;
    public bool Active { get { return kind != null; } }
    public string Kind { get { return kind; } }
    public bool PressActive { get { return pressAt >= 0; } }
    public int CompletedCycles { get; private set; }
    public event Action Finished;
    public GptWidgetMotion(WpfImage image, ScaleTransform pressScale) {
        girl=image; press=pressScale;
        var group=new TransformGroup(); group.Children.Add(stretch); group.Children.Add(alignment);
        girl.RenderTransformOrigin=new System.Windows.Point(.5,1); girl.RenderTransform=group;
        timer=new DispatcherTimer(DispatcherPriority.Render, girl.Dispatcher); timer.Interval=TimeSpan.FromMilliseconds(16); timer.Tick += Tick;
    }
    public void SetBaseImage(BitmapSource image) { normal=image; if (!Active) SetImage(image, true); }
    void SetImage(BitmapSource image, bool bottomAligned) {
        girl.Source=image;
        if (image == null) return;
        var bgra=new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0);
        alphaWidth=bgra.PixelWidth; alphaHeight=bgra.PixelHeight; alpha=new byte[alphaWidth*alphaHeight*4]; bgra.CopyPixels(alpha, alphaWidth*4, 0);
        int bottom=alphaHeight;
        if (bottomAligned) {
            bool found=false;
            for (int y=alphaHeight-1; y>=0 && !found; y--) for (int x=0; x<alphaWidth; x++) if (alpha[(y*alphaWidth+x)*4+3]>10) { bottom=y+1; found=true; break; }
        }
        double width=girl.Width, height=girl.Height;
        if (Double.IsNaN(width) || width<=0) width=208;
        if (Double.IsNaN(height) || height<=0) height=208;
        double fit=Math.Min(width/alphaWidth,height/alphaHeight);
        alignment.Y=(height-alphaHeight*fit)/2+(bottomAligned ? (alphaHeight-bottom)*fit : 0)+AnimationPadding;
    }
    public bool Contains(double x, double y, double width, double height) {
        if (alpha == null) return false;
        double fit=Math.Min(width/alphaWidth,height/alphaHeight); if (fit<=0) return false;
        int px=(int)Math.Floor((x-(width-alphaWidth*fit)/2)/fit), py=(int)Math.Floor((y-(height-alphaHeight*fit)/2)/fit);
        return px>=0 && py>=0 && px<alphaWidth && py<alphaHeight && alpha[(py*alphaWidth+px)*4+3]>10;
    }
    public void Reposition(double padding) { AnimationPadding=padding; if (!Active && normal!=null) SetImage(normal,true); }
    public void Press(bool down) {
        if (disposed || Active) return;
        double now=clock.Elapsed.TotalMilliseconds, speed=Math.Max(.5, Math.Min(3,Speed));
        if (down) {
            held=true; pressAt=now; releaseAt=-1; attack=Immediate ? 0 : 140/speed; rebound=220/speed;
            fromX=press.ScaleX; fromY=press.ScaleY;
            if (Immediate) { press.ScaleX=1.04; press.ScaleY=.89; }
        } else {
            held=false; if (pressAt<0) return;
            releaseAt=Math.Max(now,pressAt+attack+Math.Max(40,50/speed));
        }
        timer.Start();
    }
    public void Play(string value, string path, int cycles) {
        if (value!="squish" && value!="dance" && value!="zero") throw new ArgumentException("Unknown animation.");
        Stop();
        try {
            if (value=="squish") {
                using (var file=File.OpenRead(path)) {
                    if (file.Length>20*1024*1024) throw new InvalidDataException("Image is too large.");
                    var image=new BitmapImage(); image.BeginInit(); image.CacheOption=BitmapCacheOption.OnLoad; image.StreamSource=file; image.EndInit(); image.Freeze(); squishImage=image;
                }
                SetImage(squishImage,true);
            } else { gif=new GptWidgetGif(path); SetImage(gif.Decode(0),false); lastFrame=0; }
            kind=value; repeats=Math.Max(0,Math.Min(10,cycles)); CompletedCycles=0; eggAt=clock.Elapsed.TotalMilliseconds; timer.Start();
        } catch { Stop(); throw; }
    }
    void Tick(object sender, EventArgs args) {
        double now=clock.Elapsed.TotalMilliseconds;
        if (Active) {
            double elapsed=now-eggAt, period=gif!=null ? gif.Duration : 800;
            CompletedCycles=(int)(elapsed/period);
            if (repeats>0 && elapsed>=period*repeats) { Stop(); var done=Finished; if(done!=null)done(); return; }
            if (gif!=null) { int frame=gif.FrameAt(elapsed); if(frame!=lastFrame){SetImage(gif.Decode(frame),false);lastFrame=frame;} }
            else { var scale=GptWidgetMotionMath.Stretch(elapsed);stretch.ScaleX=scale[0];stretch.ScaleY=scale[1]; }
            return;
        }
        if (pressAt>=0) {
            if (!held && releaseAt>=0 && now>=releaseAt) {
                double t=GptWidgetMotionMath.Ease((now-releaseAt)/rebound);
                press.ScaleX=1.04+(1-1.04)*t;press.ScaleY=.89+(1-.89)*t;
                if (t>=1) { pressAt=-1;releaseAt=-1;timer.Stop(); }
            } else {
                double t=attack==0 ? 1 : GptWidgetMotionMath.Ease((now-pressAt)/attack);
                press.ScaleX=fromX+(1.04-fromX)*t;press.ScaleY=fromY+(.89-fromY)*t;
            }
        } else timer.Stop();
    }
    public void Stop() {
        timer.Stop(); if(gif!=null){gif.Dispose();gif=null;}
        kind=null;squishImage=null;lastFrame=-1;pressAt=-1;releaseAt=-1;held=false;
        stretch.ScaleX=stretch.ScaleY=press.ScaleX=press.ScaleY=1;
        if(normal!=null)SetImage(normal,true);
    }
    public void Dispose() { if(disposed)return;Stop();timer.Tick-=Tick;disposed=true;alpha=null;normal=null; }
}

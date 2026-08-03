using Foundation;
using Microsoft.Maui;
using Microsoft.Maui.Hosting;

namespace Shenai.Ce.Maui.Minimal;

[Register("AppDelegate")]
public class AppDelegate : MauiUIApplicationDelegate
{
    protected override MauiApp CreateMauiApp() => MauiProgram.CreateMauiApp();
}

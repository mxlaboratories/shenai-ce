using Microsoft.Maui;
using Microsoft.Maui.Hosting;
using CommunityToolkit.Maui;
using Shenai.Maui;

namespace Shenai.Ce.Maui.Minimal;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .UseMauiCommunityToolkit()
            .UseShenai();

        return builder.Build();
    }
}

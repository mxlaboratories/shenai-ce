using Shenai.Maui;

namespace Shenai.Ce.Maui.Minimal;

public partial class MainPage : ContentPage
{
    private bool _isActive;
    private bool _initialized;

    public MainPage()
    {
        InitializeComponent();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        _isActive = true;

        if (_initialized)
        {
            return;
        }

        StatusLabel.IsVisible = true;

        if (string.IsNullOrWhiteSpace(CeConfig.ApiKey))
        {
            StatusLabel.Text = "Missing SHENAI_API_KEY";
            return;
        }

        try
        {
            var result = await ShenaiSdk.InitializeAsync(
                CeConfig.ApiKey,
                CeConfig.UserId,
                new InitializationSettings
                {
                    InitializationMode = InitializationMode.MEASUREMENT
                });

            if (result == InitializationResult.OK)
            {
                _initialized = true;
                if (!_isActive)
                {
                    await ShenaiSdk.DeinitializeAsync();
                    _initialized = false;
                    return;
                }

                await ShenaiSdk.SetLanguageAsync(CeConfig.Language);
                if (_isActive)
                {
                    StatusLabel.IsVisible = false;
                }
                return;
            }

            if (_isActive)
            {
                StatusLabel.Text = $"Initialization failed: {result}";
            }
        }
        catch (Exception ex)
        {
            if (_isActive)
            {
                StatusLabel.Text = ex.Message;
            }
        }
    }

    protected override async void OnDisappearing()
    {
        base.OnDisappearing();
        _isActive = false;
        if (_initialized)
        {
            _initialized = false;
            await ShenaiSdk.DeinitializeAsync();
        }
    }
}

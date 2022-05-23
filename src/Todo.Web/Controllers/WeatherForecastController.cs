using Microsoft.AspNetCore.Mvc;
using Microsoft.Net.Http.Headers;

namespace Todo.Web.Controllers;

[ApiController]
[Route("[controller]")]
public class WeatherForecastController : ControllerBase
{
    private readonly ILogger<WeatherForecastController> _logger;
    private readonly IHttpClientFactory _httpClientFactory;

    public WeatherForecastController(ILogger<WeatherForecastController> logger, IHttpClientFactory httpClientFactory)
    {
        _logger = logger;
        _httpClientFactory = httpClientFactory;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var httpRequestMessage = new HttpRequestMessage(
            HttpMethod.Get,
            "https://localhost:7080/WeatherForecast")
        {
            Headers =
            {
                { HeaderNames.Accept, "application/json" }
            }
        };

        var httpClient = _httpClientFactory.CreateClient();

        var httpResponseMessage = await httpClient.SendAsync(httpRequestMessage);

        if (httpResponseMessage.IsSuccessStatusCode)
        {

            var response = await httpResponseMessage.Content.ReadFromJsonAsync<IEnumerable<WeatherForecast>>();
            return Ok(response);
        }
        return BadRequest();
    }
}

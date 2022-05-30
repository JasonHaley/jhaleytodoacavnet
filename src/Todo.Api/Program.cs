using Azure.Identity;
using Microsoft.Azure.Cosmos;
using Todo.Api;

var credential = new DefaultAzureCredential();
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<ListsRepository>();

builder.Services.AddSingleton(_ => new CosmosClient(builder.Configuration["AZURE_COSMOS_ENDPOINT"], credential, new CosmosClientOptions()
{
    SerializerOptions = new CosmosSerializationOptions
    {
        PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase
    }
}));
builder.Services.AddControllers();
builder.Services.AddApplicationInsightsTelemetry(builder.Configuration["APPINSIGHTS_INSTRUMENTATIONKEY"]);

var app = builder.Build();

app.UseCors(policy =>
{
    policy.AllowAnyOrigin();
    policy.AllowAnyHeader();
    policy.AllowAnyMethod();
});

app.MapControllers();
app.Run();
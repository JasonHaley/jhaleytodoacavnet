using Microsoft.Net.Http.Headers;
using System.Text.Json;
using Todo.Models;

namespace Todo.Web
{
    public class ListService
    {
        private readonly string _apiBaseUrl;
        private readonly HttpClient _httpClient;
        public ListService(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _apiBaseUrl = configuration["API_BASE_URL"];
        }

        public async Task<IEnumerable<TodoList>?> GetListsAsync(int? skip = null, int? batchSize = null)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Get,
                $"{_apiBaseUrl}/lists?skip={skip}&batchSize={batchSize}")
            {
                Headers =
                {
                    { HeaderNames.Accept, "application/json" }
                }
            };

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (httpResponseMessage.IsSuccessStatusCode)
            {
                return await httpResponseMessage.Content.ReadFromJsonAsync<IEnumerable<TodoList>>();
            }
            throw new Exception("Error retreiving lists");
        }

        public async Task<TodoList?> GetListAsync(string listId)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Get,
                $"{_apiBaseUrl}/lists/{listId}")
            {
                Headers =
                {
                    { HeaderNames.Accept, "application/json" }
                }
            };

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (httpResponseMessage.IsSuccessStatusCode)
            {
                return await httpResponseMessage.Content.ReadFromJsonAsync<TodoList>();
            }
            throw new Exception("Error retreiving list");
        }

        public async Task<TodoList?> AddListAsync(TodoList list)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Post,
                $"{_apiBaseUrl}/lists")
            {
                Headers =
                {
                    { HeaderNames.Accept, "application/json" }
                },
                Content = new StringContent(JsonSerializer.Serialize(list), System.Text.Encoding.UTF8, "application/json")
            };

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (!httpResponseMessage.IsSuccessStatusCode)
            {
                throw new Exception("Error adding list");
            }

            return await httpResponseMessage.Content.ReadFromJsonAsync<TodoList>();
        }

        public async Task<TodoList?> UpdateListAsync(TodoList list)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Put,
                $"{_apiBaseUrl}/lists/{list.Id}")
            {
                Headers =
                {
                    { HeaderNames.Accept, "application/json" }
                },
                Content = new StringContent(JsonSerializer.Serialize(list), System.Text.Encoding.UTF8, "application/json")
            };

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (!httpResponseMessage.IsSuccessStatusCode)
            {
                throw new Exception("Error updating list");
            }

            return await httpResponseMessage.Content.ReadFromJsonAsync<TodoList>();
        }

        public async Task DeleteListAsync(string listId)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Delete,
                $"{_apiBaseUrl}/lists/{listId}");

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (!httpResponseMessage.IsSuccessStatusCode)
            {
                throw new Exception("Error deleting list");
            }
        }

        public async Task<IEnumerable<TodoItem>?> GetListItemsAsync(string listId, int? skip = null, int? batchSize = null)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Get,
                $"{_apiBaseUrl}/lists/{listId}/items?skip={skip}&batchSize={batchSize}")
            {
                Headers =
                {
                    { HeaderNames.Accept, "application/json" }
                }
            };

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (httpResponseMessage.IsSuccessStatusCode)
            {
                return await httpResponseMessage.Content.ReadFromJsonAsync<IEnumerable<TodoItem>>();
            }
            throw new Exception("Error retreiving items");
        }

        public async Task<TodoItem?> AddListItemAsync(TodoItem item)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Post,
                $"{_apiBaseUrl}/lists/{item.ListId}/items")
            {
                Headers =
                {
                    { HeaderNames.Accept, "application/json" }
                },
                Content = new StringContent(JsonSerializer.Serialize(item), System.Text.Encoding.UTF8, "application/json")
            };

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (httpResponseMessage.IsSuccessStatusCode)
            {
                return await httpResponseMessage.Content.ReadFromJsonAsync<TodoItem>();
            }
            throw new Exception("Error adding item");
        }

        public async Task<TodoItem?> GetListItemAsync(string listId, string itemId)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Get,
                $"{_apiBaseUrl}/lists/{listId}/items/{itemId}")
            {
                Headers =
                {
                    { HeaderNames.Accept, "application/json" }
                }
            };

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (httpResponseMessage.IsSuccessStatusCode)
            {
                return await httpResponseMessage.Content.ReadFromJsonAsync<TodoItem>();
            }
            throw new Exception("Error retreiving item");
        }

        public async Task<TodoItem?> UpdateListItemAsync(TodoItem item)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Put,
                $"{_apiBaseUrl}/lists/{item.ListId}/items/{item.Id}")
            {
                Headers =
                {
                    { HeaderNames.Accept, "application/json" }
                },
                Content = new StringContent(JsonSerializer.Serialize(item), System.Text.Encoding.UTF8, "application/json")
            };

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (httpResponseMessage.IsSuccessStatusCode)
            {
                return await httpResponseMessage.Content.ReadFromJsonAsync<TodoItem>();
            }
            throw new Exception("Error updating item");
        }

        public async Task DeleteListItemAsync(string listId, string itemId)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Delete,
                $"{_apiBaseUrl}/lists/{listId}/items/{itemId}");

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (!httpResponseMessage.IsSuccessStatusCode)
            {
                throw new Exception("Error deleting item");
            }
        }

        public async Task<IEnumerable<TodoItem>?> GetListItemsByStateAsync(string listId, string state, int? skip = null, int? batchSize = null)
        {
            var httpRequestMessage = new HttpRequestMessage(
                HttpMethod.Get,
                $"{_apiBaseUrl}/lists/{listId}/state/{state}?skip={skip}&batchSize={batchSize}")
            {
                Headers =
                {
                    { HeaderNames.Accept, "application/json" }
                }
            };

            var httpResponseMessage = await _httpClient.SendAsync(httpRequestMessage);

            if (httpResponseMessage.IsSuccessStatusCode)
            {
                return await httpResponseMessage.Content.ReadFromJsonAsync<IEnumerable<TodoItem>>();
            }
            throw new Exception("Error retreiving items by state");
        }
    }
}

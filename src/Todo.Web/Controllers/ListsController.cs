using Microsoft.AspNetCore.Mvc;
using Todo.Models;

namespace Todo.Web;

[ApiController]
[Route("/v1/lists")]
public class ListsController : ControllerBase
{
    private readonly ILogger<ListsController> _logger;
    private readonly ListService _listService;

    public ListsController(ILogger<ListsController> logger, ListService listService)
    {
        _logger = logger;
        _listService = listService;
    }

    [HttpGet]
    [ProducesResponseType(200)]
    public async Task<ActionResult<IEnumerable<TodoList>>> GetLists([FromQuery] int? skip = null, [FromQuery] int? batchSize = null)
    {
        return Ok(await _listService.GetListsAsync(skip, batchSize));
    }

    [HttpPost]
    [ProducesResponseType(201)]
    public async Task<ActionResult> CreateList([FromBody] CreateUpdateTodoList list)
    {
        var todoList = new TodoList(list.name)
        {
            Description = list.description
        };

        var inserted = await _listService.AddListAsync(todoList);

        return CreatedAtAction(nameof(GetList), new { list_id = inserted?.Id }, inserted);
    }

    [HttpGet("{list_id}")]
    [ProducesResponseType(200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<IEnumerable<TodoList>>> GetList(string list_id)
    {
        var list = await _listService.GetListAsync(list_id);

        return list == null ? NotFound() : Ok(list);
    }

    [HttpPut("{list_id}")]
    [ProducesResponseType(200)]
    public async Task<ActionResult<TodoList>> UpdateList(string list_id, [FromBody] CreateUpdateTodoList list)
    {
        var existingList = await _listService.GetListAsync(list_id);
        if (existingList == null)
        {
            return NotFound();
        }

        existingList.Name = list.name;
        existingList.Description = list.description;
        existingList.UpdatedDate = DateTimeOffset.UtcNow;

        var updatedList = await _listService.UpdateListAsync(existingList);

        return Ok(updatedList);
    }

    [HttpDelete("{list_id}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(404)]
    public async Task<ActionResult> DeleteList(string list_id)
    {
        if (await _listService.GetListAsync(list_id) == null)
        {
            return NotFound();
        }

        await _listService.DeleteListAsync(list_id);

        return NoContent();
    }

    [HttpGet("{list_id}/items")]
    [ProducesResponseType(200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<IEnumerable<TodoItem>>> GetListItems(string list_id, [FromQuery] int? skip = null, [FromQuery] int? batchSize = null)
    {
        if (await _listService.GetListAsync(list_id) == null)
        {
            return NotFound();
        }
        return Ok(await _listService.GetListItemsAsync(list_id, skip, batchSize));
    }

    [HttpPost("{list_id}/items")]
    [ProducesResponseType(201)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<TodoItem>> CreateListItem(string list_id, [FromBody] CreateUpdateTodoItem item)
    {
        if (await _listService.GetListAsync(list_id) == null)
        {
            return NotFound();
        }

        var newItem = new TodoItem(list_id, item.name)
        {
            Description = item.description,
            State = item.state,
            CreatedDate = DateTimeOffset.UtcNow
        };

        var inserted = await _listService.AddListItemAsync(newItem);

        return CreatedAtAction(nameof(GetListItem), new { list_id = list_id, item_id = inserted?.Id }, inserted);
    }

    [HttpGet("{list_id}/items/{item_id}")]
    [ProducesResponseType(200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<TodoItem>> GetListItem(string list_id, string item_id)
    {
        if (await _listService.GetListAsync(list_id) == null)
        {
            return NotFound();
        }

        var item = await _listService.GetListItemAsync(list_id, item_id);

        return item == null ? NotFound() : Ok(item);
    }

    [HttpPut("{list_id}/items/{item_id}")]
    [ProducesResponseType(200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<TodoItem>> UpdateListItem(string list_id, string item_id, [FromBody] CreateUpdateTodoItem item)
    {
        var existingItem = await _listService.GetListItemAsync(list_id, item_id);
        if (existingItem == null)
        {
            return NotFound();
        }

        existingItem.Name = item.name;
        existingItem.Description = item.description;
        existingItem.CompletedDate = item.completedDate;
        existingItem.DueDate = item.dueDate;
        existingItem.State = item.state;
        existingItem.UpdatedDate = DateTimeOffset.UtcNow;

        var updatedItem = await _listService.UpdateListItemAsync(existingItem);

        return Ok(updatedItem);
    }

    [HttpDelete("{list_id}/items/{item_id}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(404)]
    public async Task<ActionResult> DeleteListItem(string list_id, string item_id)
    {
        if (await _listService.GetListItemAsync(list_id, item_id) == null)
        {
            return NotFound();
        }

        await _listService.DeleteListItemAsync(list_id, item_id);

        return NoContent();
    }

    [HttpGet("{list_id}/state/{state}")]
    [ProducesResponseType(200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<IEnumerable<TodoItem>>> GetListItemsByState(string list_id, string state, [FromQuery] int? skip = null, [FromQuery] int? batchSize = null)
    {
        if (await _listService.GetListAsync(list_id) == null)
        {
            return NotFound();
        }

        return Ok(await _listService.GetListItemsByStateAsync(list_id, state, skip, batchSize));
    }

    public record CreateUpdateTodoList(string name, string? description = null);
    public record CreateUpdateTodoItem(string name, string state, DateTimeOffset? dueDate, DateTimeOffset? completedDate, string? description = null);
}

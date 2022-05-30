namespace Todo.Models;

public class TodoItem
{
    public TodoItem(string listId, string name)
    {
        ListId = listId;
        Name = name;
    }
    public string? Id { get; set; }
    public string ListId { get; set; }
    public string Name { get; set; }
    public string State { get; set; } = TodoItemState.Todo;
    public string? Description { get; set; }
    public DateTimeOffset? DueDate { get; set; }
    public DateTimeOffset? CompletedDate { get; set; }
    public DateTimeOffset? CreatedDate { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedDate { get; set; }
}

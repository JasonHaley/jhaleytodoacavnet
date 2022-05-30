namespace Todo.Models;
public class TodoList
{
    public TodoList()
    {
        Name = "test";
    }
    public TodoList(string name)
    {
        Name = name;
    }

    public string? Id { get; set; }
    public string Name { get; set; }
    public string? Description { get; set;  }
    public DateTimeOffset CreatedDate { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedDate { get; set; }
}

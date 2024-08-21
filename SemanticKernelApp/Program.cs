var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// 

app.UseHttpsRedirection();

app.MapPost("/message", (Message message) =>
{
    Console.WriteLine($"Message received: {message.message}");
    return message.message;
})
.WithName("PostMessage")
.WithOpenApi();

app.Run();

record Message(string message);
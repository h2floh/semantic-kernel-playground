using Azure.AI.OpenAI;
using Azure.Identity;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using System.Text.Json;
using Resources;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Azure Key Vault to the configuration
var keyVaultName = builder.Configuration["KeyVaultName"];
var keyVaultUri = new Uri($"https://{keyVaultName}.vault.azure.net/");

builder.Configuration.AddAzureKeyVault(keyVaultUri, new DefaultAzureCredential());

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Init semantic Kernel
// Create a kernel with Azure OpenAI chat completion
var semanticBuilder = Kernel.CreateBuilder().AddAzureOpenAIChatCompletion(app.Configuration["openAiDeployment"]!, app.Configuration["openAiEndpoint"]!, app.Configuration["openaikey"]!);

// Add enterprise components
semanticBuilder.Services.AddLogging(services => services.AddConsole().SetMinimumLevel(LogLevel.Trace));

// Build the kernel
Kernel kernel = semanticBuilder.Build();
var chatCompletionService = kernel.GetRequiredService<IChatCompletionService>();

// Add Azure Chat Extensions PREVIEW
// var azureSearchExtensionConfigurationCE = new AzureSearchChatExtensionConfiguration
// {
//     SearchEndpoint = new Uri(app.Configuration["AZURE_AI_SEARCH_ENDPOINT"]!),
//     Authentication = new OnYourDataApiKeyAuthenticationOptions(app.Configuration["AZURE-AI-SEARCH-API-KEY"]!),
//     IndexName = app.Configuration["AZURE_AI_SEARCH_INDEX_CE"]!
// };

// var azureSearchExtensionConfigurationAZTFMOD = new AzureSearchChatExtensionConfiguration
// {
//     SearchEndpoint = new Uri(app.Configuration["AZURE_AI_SEARCH_ENDPOINT"]!),
//     Authentication = new OnYourDataApiKeyAuthenticationOptions(app.Configuration["AZURE-AI-SEARCH-API-KEY"]!),
//     IndexName = app.Configuration["AZURE_AI_SEARCH_INDEX_AZTFMOD"]!
// };

// var chatExtensionsOptions = new AzureChatExtensionsOptions { Extensions = { azureSearchExtensionConfigurationAZTFMOD } };



// Enable planning
#pragma warning disable SKEXP0010
OpenAIPromptExecutionSettings openAIPromptExecutionSettings = new() 
{
    ToolCallBehavior = ToolCallBehavior.AutoInvokeKernelFunctions,
    ResponseFormat = ChatCompletionsResponseFormat.JsonObject,
    //AzureChatExtensionsOptions = chatExtensionsOptions
};
#pragma warning restore SKEXP0010

// var function = kernel.CreateFunctionFromPrompt(prompt, executionSettings: openAIPromptExecutionSettings);
var generateCEConfigYaml = EmbeddedResource.Read("ceconfig.yaml");
var function = kernel.CreateFunctionFromPromptYaml(generateCEConfigYaml);

// Create a history store the conversation
var history = new ChatHistory();
var ragHelper = new RAGHelpers.RAGHelpers(app);

app.MapPost("/message", async (Message message) =>
{
    Console.WriteLine($"Message received: {message.message}");
    // Add user input
    // history.AddUserMessage(message.message);

    // Get the response from the AI
    // var result = await chatCompletionService.GetChatMessageContentAsync(
    //     history,
    //     executionSettings: openAIPromptExecutionSettings,
    //     kernel: kernel);

    // Invoke the prompt
    var result = await kernel.InvokeAsync(function, arguments: new()
    {
        { "ce_examples", await ragHelper.CreateCloudEnablerContextAsync(message.message) },
        { "aztfmod_examples", await ragHelper.CreateAZTFMODContextAsync(message.message) },
        { "user_question", message.message },
    });
    // Add the message from the agent to the chat history
    // history.AddMessage(result.Role, result.Content ?? string.Empty);

    return JsonSerializer.Serialize<Message>(new Message(result.ToString() ?? string.Empty));
})
.WithName("PostMessage")
.WithOpenApi();

app.Run();

record Message(string message);
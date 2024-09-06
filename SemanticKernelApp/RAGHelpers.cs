using Azure;
using Azure.Identity;
using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using AzureAISearchIndices;
using System.ComponentModel;
using Microsoft.SemanticKernel;

namespace RAGHelpers {

    public class RAGPlugin {
        [KernelFunction, Description("Get a list of current configuration tvfars files")]
        public static string GetConfiguration(RAGHelpers ragHelper, string message) {
            return ragHelper.CreateCloudEnablerContextAsync(message).ConfigureAwait(false).GetAwaiter().GetResult();
        }

        [KernelFunction, Description("Get a list of example configuration tvfars files")]
        public static string GetExampleConfiguration(RAGHelpers ragHelper, string message) {
            return ragHelper.CreateAZTFMODContextAsync(message).ConfigureAwait(false).GetAwaiter().GetResult();
        }
    }

    public class RAGHelpers {
        private SearchClient? searchClientCE;
        private SearchClient? searchClientAZTFMOD;
        public RAGHelpers(WebApplication app, DefaultAzureCredential credential) {
            // Prepare Azure Search
            var indexCE =  app.Configuration["AZURE_AI_SEARCH_INDEX_CE"]!;
            var indexAZTFMOD =  app.Configuration["AZURE_AI_SEARCH_INDEX_AZTFMOD"]!;
            var url = $"https://{app.Configuration["AZURE_SERVICE_PREFIX"]}.search.windows.net";
            var endpoint = new Uri(url);
            this.searchClientCE = new SearchClient(endpoint, indexCE, credential);
            this.searchClientAZTFMOD = new SearchClient(endpoint, indexAZTFMOD, credential);
        }

        public async Task<string> CreateCloudEnablerContextAsync(string message) {
            // Prepare context for invocation
            return await SearchAzureSearchAsync(this.searchClientCE!, message);
        }

        public async Task<string> CreateAZTFMODContextAsync(string message) {
            // Prepare context for invocation
            return await SearchAzureSearchAsync(this.searchClientAZTFMOD!, message);
        }

        // Search Azure Search, input provided is a search client and a message
        private async Task<string> SearchAzureSearchAsync(SearchClient searchClient, string message)
        {
            try
            {
                // Create a search query
                SearchOptions options = new SearchOptions
                {
                    IncludeTotalCount = true,
                    Size = 3, // Limit the number of results
                    //Filter = "metadata_storage_file_extension eq '.tfvars'"
                };

                // Execute the search
                SearchResults<CEIndex> results = await searchClient.SearchAsync<CEIndex>(message, options);
                string partPromptResult = String.Empty;
                // Process the results
                foreach (SearchResult<CEIndex> result in results.GetResults())
                {
                    // Assuming you want to return the first result's content as a string
                    partPromptResult += $"Filename: {result.Document.FileName}\nContent:{result.Document.Content}\n\n" ;
                }

                return partPromptResult;
            }
            catch (RequestFailedException ex)
            {
                // Handle the exception (log it, rethrow it, etc.)
                return $"Search failed: {ex.Message}";
            }
        }
    }
}


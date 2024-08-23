using Azure;
using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Models;
using AzureAISearchIndices;

namespace RAGHelpers {

    public class RAGHelpers {
        private SearchClient? searchClientCE;
        private SearchClient? searchClientAZTFMOD;
        public RAGHelpers(WebApplication app) {
            // Prepare Azure Search
            var indexCE =  app.Configuration["AZURE_AI_SEARCH_INDEX_CE"]!;
            var indexAZTFMOD =  app.Configuration["AZURE_AI_SEARCH_INDEX_AZTFMOD"]!;
            AzureKeyCredential credential = new AzureKeyCredential(app.Configuration["AZURE-AI-SEARCH-API-KEY"]!);
            this.searchClientCE = new SearchClient(new Uri(app.Configuration["AZURE_AI_SEARCH_ENDPOINT"]!), indexCE, credential);
            this.searchClientAZTFMOD = new SearchClient(new Uri(app.Configuration["AZURE_AI_SEARCH_ENDPOINT"]!), indexAZTFMOD, credential);
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


using System.Text.Json.Serialization;

namespace AzureAISearchIndices
{

    public sealed class CEIndex
    {
        [JsonPropertyName("content")]
        public required string Content { get; set; }

        [JsonPropertyName("metadata_storage_name")]
        public required string FileName { get; set; }
    }

}
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Serialization;
using System.Web;

namespace AzureAISearchIndices
{

    public sealed class CEIndex
    {
        [JsonPropertyName("content")]
        public required string Content { get; set; }

        private string _fileName = string.Empty;

        [JsonPropertyName("metadata_storage_path")]
        public required string FileName
        {
            get => _fileName;
            set => _fileName = DecodeBase64(value);
        }

        private string DecodeBase64(string encodedString)
        {
            var encodedStringWithoutTrailingCharacter = encodedString.Substring(0, encodedString.Length - 1);
            var encodedBytes = Microsoft.AspNetCore.WebUtilities.WebEncoders.Base64UrlDecode(encodedStringWithoutTrailingCharacter);
            return HttpUtility.UrlDecode(encodedBytes, Encoding.UTF8);
        }
    }

    public sealed class AZTFMODIndex
    {
        [JsonPropertyName("content")]
        public required string Content { get; set; }

        [JsonPropertyName("metadata_storage_path")]
        public required string FileName { get; set; }
    }

    

}
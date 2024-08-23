// Copyright (c) Microsoft. All rights reserved.
// Thank you! https://github.com/microsoft/semantic-kernel/blob/163d512753a1dd765c1b9e74859e55e8b7d2d5b6/dotnet/src/InternalUtilities/samples/InternalUtilities/ConfigurationNotFoundException.cs
public sealed class ConfigurationNotFoundException : Exception
{
    public string? Section { get; }
    public string? Key { get; }

    public ConfigurationNotFoundException(string section, string key)
        : base($"Configuration key '{section}:{key}' not found")
    {
        this.Section = section;
        this.Key = key;
    }

    public ConfigurationNotFoundException(string section)
    : base($"Configuration section '{section}' not found")
    {
        this.Section = section;
    }

    public ConfigurationNotFoundException() : base()
    {
    }

    public ConfigurationNotFoundException(string? message, Exception? innerException) : base(message, innerException)
    {
    }
}
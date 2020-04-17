// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Globalization;

    [AttributeUsage(AttributeTargets.Method, Inherited = false)]
    public sealed class IssueAttribute : Attribute
    {
        private static readonly Uri s_BaseUri =
            new Uri("https://github.com/chtoucas/Abc.Maybe/issues/", UriKind.Absolute);

        public IssueAttribute(int id) : this(id, String.Empty) { }

        public IssueAttribute(int id, string? message)
        {
            Id = id;
            Message = message;
        }

        public int Id { get; }
        public string? Message { get; }

        // https://github.com/chtoucas/Abc.Maybe/issues/{Id}
        public Uri Uri => new Uri(s_BaseUri, Id.ToString(CultureInfo.InvariantCulture));

        public override string ToString() => Message ?? Uri.ToString();
    }
}

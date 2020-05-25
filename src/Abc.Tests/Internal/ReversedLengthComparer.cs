// See LICENSE in the project root for license information.

using System.Collections;

// Shorter strings come first.
internal sealed class ReversedLengthComparer : IComparer
{
    public int Compare(object? x, object? y)
    {
        if (x is string left && y is string right)
        {
            return -left.Length.CompareTo(right.Length);
        }

        return Comparer.Default.Compare(x, y);
    }
}

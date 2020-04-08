// See LICENSE in the project root for license information.

namespace Abc.Utilities
{
    using System;
    using System.Diagnostics.CodeAnalysis;

    /// <summary>
    /// Indicates that a method or a field has been made internal for testing
    /// purposes.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    [ExcludeFromCodeCoverage]
    [AttributeUsage(
        AttributeTargets.Constructor
        | AttributeTargets.Method
        | AttributeTargets.Property
        | AttributeTargets.Field)]
    internal sealed class InternalForTestingAttribute : Attribute
    {
        /// <summary>
        /// Obtains the accessibiliy level that the method or field would have
        /// had otherwise.
        /// </summary>
        // On ne vérifie pas la valeur passée au "setter", mais a priori ce
        // dernier ne devrait accepter que les valeurs "Private" ou "Protected".
        public AccessibilityLevel GenuineAccessibility { get; set; }
            = AccessibilityLevel.Private;
    }
}

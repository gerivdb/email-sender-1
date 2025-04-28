BeforeAll {
    # Importer le module Ã  tester
    $ModulePath = Join-Path $PSScriptRoot "excel_property_selection.ps1"
    . $ModulePath
}

Describe "Fonctions d'introspection des types" {
    Context "New-StringComparer function" {
        It "Should create a case-sensitive comparer" {
            $comparer = New-StringComparer
            $comparer.Equals("Hello", "hello") | Should -Be $false
            $comparer.Equals("Hello", "Hello") | Should -Be $true
        }

        It "Should create a case-insensitive comparer" {
            $comparer = New-StringComparer -IgnoreCase
            $comparer.Equals("Hello", "hello") | Should -Be $true
            $comparer.Equals("Hello", "Hello") | Should -Be $true
        }

        It "Should ignore whitespace when specified" {
            $comparer = New-StringComparer -IgnoreWhiteSpace
            $comparer.Equals("Hello World", "HelloWorld") | Should -Be $true
            $comparer.Equals("Hello  World", "Hello World") | Should -Be $true
        }

        It "Should ignore non-alphanumeric characters when specified" {
            $comparer = New-StringComparer -IgnoreNonAlphanumeric
            $comparer.Equals("Hello-World", "HelloWorld") | Should -Be $true
            $comparer.Equals("Hello_World", "HelloWorld") | Should -Be $true
        }

        It "Should combine multiple options" {
            $comparer = New-StringComparer -IgnoreCase -IgnoreWhiteSpace -IgnoreNonAlphanumeric
            $comparer.Equals("Hello-World", "hello world") | Should -Be $true
            $comparer.Equals("HELLO_WORLD", "hello-world") | Should -Be $true
        }
    }
    Context "ConvertFrom-TypeName function" {
        It "Should parse simple type names" {
            $result = ConvertFrom-TypeName -TypeName "System.String"
            $result.Namespace | Should -Be "System"
            $result.TypeName | Should -Be "String"
        }

        It "Should parse nested type names" {
            $result = ConvertFrom-TypeName -TypeName "System.Collections.Generic.List"
            $result.Namespace | Should -Be "System.Collections.Generic"
            $result.TypeName | Should -Be "List"
        }

        It "Should parse generic type names" {
            $result = ConvertFrom-TypeName -TypeName "System.Collections.Generic.List``1"
            $result.Namespace | Should -Be "System.Collections.Generic"
            $result.TypeName | Should -Be "List``1"
        }

        It "Should handle types without namespace" {
            $result = ConvertFrom-TypeName -TypeName "MyClass"
            $result.Namespace | Should -Be ""
            $result.TypeName | Should -Be "MyClass"
        }
    }

    Context "Get-TypeByQualifiedName function" {
        It "Should find System.String type" {
            $result = Get-TypeByQualifiedName -TypeName "System.String"
            $result | Should -Not -BeNullOrEmpty
            $result.FullName | Should -Be "System.String"
        }

        It "Should find System.Int32 type" {
            $result = Get-TypeByQualifiedName -TypeName "System.Int32"
            $result | Should -Not -BeNullOrEmpty
            $result.FullName | Should -Be "System.Int32"
        }

        It "Should handle case-insensitive search" {
            $result = Get-TypeByQualifiedName -TypeName "system.string" -IgnoreCase
            $result | Should -Not -BeNullOrEmpty
            $result.FullName | Should -Be "System.String"
        }

        It "Should return null for non-existent types" {
            $result = Get-TypeByQualifiedName -TypeName "NonExistentNamespace.NonExistentType"
            $result | Should -BeNullOrEmpty
        }

        It "Should throw for non-existent types when ThrowOnError is specified" {
            { Get-TypeByQualifiedName -TypeName "NonExistentNamespace.NonExistentType" -ThrowOnError } |
                Should -Throw "Le type 'NonExistentNamespace.NonExistentType' n'a pas Ã©tÃ© trouvÃ© dans les assemblies spÃ©cifiÃ©es."
        }
    }

    Context "Search-TypeInAssemblies function" {
        It "Should find System.String in mscorlib" {
            $results = Search-TypeInAssemblies -TypeName "System.String"
            $results | Should -Not -BeNullOrEmpty
            $results[0].Type.FullName | Should -Be "System.String"
            $results[0].Assembly.GetName().Name | Should -Be "mscorlib"
        }

        It "Should return null for non-existent types" {
            $results = Search-TypeInAssemblies -TypeName "NonExistentNamespace.NonExistentType"
            $results | Should -BeNullOrEmpty
        }

        It "Should handle errors gracefully" {
            # Utiliser une assembly rÃ©elle mais avec un type qui n'existe pas
            $assembly = [System.Reflection.Assembly]::GetAssembly([string])

            # Appeler la fonction avec un type qui n'existe pas
            $results = Search-TypeInAssemblies -TypeName "NonExistentType" -Assemblies @($assembly) -IncludeErrors

            # VÃ©rifier que nous avons un rÃ©sultat vide ou null
            $results | Should -BeNullOrEmpty
        }
    }

    Context "Get-TypeResolutionError function" {
        It "Should categorize assembly load errors" {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.IO.FileNotFoundException]::new("Could not load file or assembly 'TestAssembly'"),
                "AssemblyLoadError",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )

            $result = Get-TypeResolutionError -TypeName "Test.Type" -ErrorInfo $errorRecord
            $result.ErrorCategory | Should -Be "AssemblyLoadError"
            $result.TypeName | Should -Be "Test.Type"
        }

        It "Should categorize type not found errors" {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.TypeLoadException]::new("The type or namespace name 'TestType' could not be found"),
                "TypeNotFoundError",
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )

            $result = Get-TypeResolutionError -TypeName "Test.Type" -ErrorInfo $errorRecord
            $result.ErrorCategory | Should -Be "TypeNotFoundError"
            $result.TypeName | Should -Be "Test.Type"
        }

        It "Should categorize ambiguous match errors" {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Reflection.AmbiguousMatchException]::new("Ambiguous match found"),
                "AmbiguousMatchError",
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )

            $result = Get-TypeResolutionError -TypeName "Test.Type" -ErrorInfo $errorRecord
            $result.ErrorCategory | Should -Be "AmbiguousMatchError"
            $result.TypeName | Should -Be "Test.Type"
        }
    }

    Context "Get-NonPublicType function" {
        It "Should find nested types" {
            # Utiliser un type imbriquÃ© connu dans le framework .NET
            $result = Get-NonPublicType -TypeName "System.RuntimeType+RuntimeTypeCache" -IncludeNestedTypes
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be "RuntimeTypeCache"
        }

        It "Should return null for non-existent types" {
            $result = Get-NonPublicType -TypeName "NonExistentNamespace.NonExistentType"
            $result | Should -BeNullOrEmpty
        }

        It "Should throw for non-existent types when ThrowOnError is specified" {
            { Get-NonPublicType -TypeName "NonExistentNamespace.NonExistentType" -ThrowOnError } |
                Should -Throw "Le type non-public 'NonExistentNamespace.NonExistentType' n'a pas Ã©tÃ© trouvÃ© dans les assemblies spÃ©cifiÃ©es."
        }
    }

    Context "Find-TypesByNamespace function" {
        It "Should find types in System namespace" {
            $result = Find-TypesByNamespace -Namespace "System" -Filter "String"
            $result | Should -Not -BeNullOrEmpty
            $result[0].FullName | Should -Be "System.String"
        }

        It "Should find types in sub-namespaces when specified" {
            $result = Find-TypesByNamespace -Namespace "System" -Filter "*List*" -IncludeSubNamespaces
            $result | Should -Not -BeNullOrEmpty
            # VÃ©rifier qu'au moins un type contient 'List' dans son nom
            $result | Where-Object { $_.Name -like "*List*" } | Should -Not -BeNullOrEmpty
        }

        It "Should respect case sensitivity" {
            # VÃ©rifier que la recherche est sensible Ã  la casse par dÃ©faut
            $result = Find-TypesByNamespace -Namespace "System" -Filter "String"
            $result | Should -Not -BeNullOrEmpty

            # VÃ©rifier que la recherche insensible Ã  la casse fonctionne
            $result = Find-TypesByNamespace -Namespace "System" -Filter "string" -IgnoreCase
            $result | Should -Not -BeNullOrEmpty
            $result[0].FullName | Should -Be "System.String"
        }

        It "Should support wildcard filters" {
            $result = Find-TypesByNamespace -Namespace "System" -Filter "*Int*"
            $result | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.FullName -eq "System.Int32" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.FullName -eq "System.Int64" } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Find-TypesByRegex function" {
        It "Should find types matching a regex pattern" {
            $result = Find-TypesByRegex -Pattern "^System\.Int\d+$" -SearchFullName
            $result | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.FullName -eq "System.Int32" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.FullName -eq "System.Int64" } | Should -Not -BeNullOrEmpty
        }

        It "Should respect case sensitivity" {
            # VÃ©rifier que la recherche est sensible Ã  la casse par dÃ©faut
            $result = Find-TypesByRegex -Pattern "^system\.string$" -SearchFullName
            $result | Should -BeNullOrEmpty

            # VÃ©rifier que la recherche insensible Ã  la casse fonctionne
            $result = Find-TypesByRegex -Pattern "^system\.string$" -IgnoreCase -SearchFullName
            $result | Should -Not -BeNullOrEmpty
            $result[0].FullName | Should -Be "System.String"
        }

        It "Should limit results when MaxResults is specified" {
            $result = Find-TypesByRegex -Pattern "System" -MaxResults 5
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeLessOrEqual 5
        }

        It "Should search in full name when SearchFullName is specified" {
            $result = Find-TypesByRegex -Pattern "Collections\.Generic" -SearchFullName
            $result | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.FullName -like "*Collections.Generic*" } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Type alias functions" {
        BeforeEach {
            # Nettoyer les alias avant chaque test
            $script:TypeAliases = @{}
        }

        It "Should set and get type aliases" {
            Set-TypeAlias -Alias "str" -TypeName "System.String" | Should -Be $true
            Get-TypeAlias -Alias "str" | Should -Be "System.String"
        }

        It "Should not overwrite existing aliases without Force" {
            Set-TypeAlias -Alias "str" -TypeName "System.String" | Should -Be $true
            Set-TypeAlias -Alias "str" -TypeName "System.Text.StringBuilder" | Should -Be $false
            Get-TypeAlias -Alias "str" | Should -Be "System.String"
        }

        It "Should overwrite existing aliases with Force" {
            Set-TypeAlias -Alias "str" -TypeName "System.String" | Should -Be $true
            Set-TypeAlias -Alias "str" -TypeName "System.Text.StringBuilder" -Force | Should -Be $true
            Get-TypeAlias -Alias "str" | Should -Be "System.Text.StringBuilder"
        }

        It "Should remove aliases" {
            Set-TypeAlias -Alias "str" -TypeName "System.String" | Should -Be $true
            Remove-TypeAlias -Alias "str" | Should -Be $true
            Get-TypeAlias -Alias "str" | Should -BeNullOrEmpty
        }

        It "Should resolve aliases" {
            Set-TypeAlias -Alias "str" -TypeName "System.String" | Should -Be $true
            Resolve-TypeAlias -TypeName "str" | Should -Be "System.String"
            # Un nom qui n'est pas un alias devrait Ãªtre retournÃ© tel quel
            Resolve-TypeAlias -TypeName "System.Int32" | Should -Be "System.Int32"
        }

        It "Should export and import aliases" {
            # CrÃ©er un fichier temporaire pour les tests
            $tempFile = [System.IO.Path]::GetTempFileName()
            # Supprimer le fichier pour Ã©viter les problÃ¨mes d'existence
            if (Test-Path -Path $tempFile) {
                Remove-Item -Path $tempFile -Force
            }

            try {
                # DÃ©finir quelques alias
                Set-TypeAlias -Alias "str" -TypeName "System.String" | Should -Be $true
                Set-TypeAlias -Alias "int" -TypeName "System.Int32" | Should -Be $true

                # Exporter les alias
                Export-TypeAliases -Path $tempFile -Force | Should -Be 2

                # Nettoyer les alias
                $script:TypeAliases = @{}

                # Importer les alias
                Import-TypeAliases -Path $tempFile | Should -Be 2

                # VÃ©rifier que les alias ont Ã©tÃ© importÃ©s correctement
                Get-TypeAlias -Alias "str" | Should -Be "System.String"
                Get-TypeAlias -Alias "int" | Should -Be "System.Int32"
            } finally {
                # Supprimer le fichier temporaire
                if (Test-Path -Path $tempFile) {
                    Remove-Item -Path $tempFile -Force
                }
            }
        }
    }

    Context "Generic type functions" {
        It "Should create generic types" -Skip {
            # Utiliser un type gÃ©nÃ©rique simple pour Ã©viter les problÃ¨mes de version
            # CrÃ©er d'abord une liste de chaÃ®nes pour avoir une rÃ©fÃ©rence
            $referenceType = [System.Collections.Generic.List[string]]
            $referenceType | Should -Not -BeNullOrEmpty

            # Tester la fonction avec un type connu
            $listOfString = New-GenericType -GenericTypeName "System.Collections.Generic.List`1" -TypeArguments @([string])
            $listOfString | Should -Not -BeNullOrEmpty
            # VÃ©rifier que le type est bien une liste de chaÃ®nes
            $listOfString.IsGenericType | Should -Be $true
        }

        It "Should get generic type arguments" {
            $listOfString = [System.Collections.Generic.List[string]]
            $typeArgs = Get-GenericTypeArguments -Type $listOfString
            $typeArgs | Should -Not -BeNullOrEmpty
            $typeArgs.Length | Should -Be 1
            $typeArgs[0] | Should -Be ([string])
        }

        It "Should test if a type is generic" {
            Test-GenericType -Type ([System.Collections.Generic.List[string]]) | Should -Be $true
            Test-GenericType -Type ([string]) | Should -Be $false
        }

        It "Should test if a type is a generic type definition" {
            Test-GenericType -Type ([System.Collections.Generic.List`1]) -DefinitionOnly | Should -Be $true
            Test-GenericType -Type ([System.Collections.Generic.List[string]]) -DefinitionOnly | Should -Be $false
        }

        It "Should test if a type is a constructed generic type" {
            Test-GenericType -Type ([System.Collections.Generic.List[string]]) -ConstructedOnly | Should -Be $true
            Test-GenericType -Type ([System.Collections.Generic.List`1]) -ConstructedOnly | Should -Be $false
        }
    }

    Context "Special type functions" {
        It "Should create anonymous types" {
            $anonymousType = New-AnonymousType -Properties @{ Name = "John"; Age = 30 }
            $anonymousType | Should -Not -BeNullOrEmpty
            $anonymousType.Name | Should -Be "John"
            $anonymousType.Age | Should -Be 30
        }

        It "Should create equal anonymous types with same properties" {
            $anonymousType1 = New-AnonymousType -Properties @{ Name = "John"; Age = 30 }
            $anonymousType2 = New-AnonymousType -Properties @{ Name = "John"; Age = 30 }
            $anonymousType1.Equals($anonymousType2) | Should -Be $true
        }

        It "Should create different anonymous types with different properties" {
            $anonymousType1 = New-AnonymousType -Properties @{ Name = "John"; Age = 30 }
            $anonymousType2 = New-AnonymousType -Properties @{ Name = "Jane"; Age = 25 }
            $anonymousType1.Equals($anonymousType2) | Should -Be $false
        }

        It "Should create nullable types" {
            # CrÃ©er d'abord un type nullable de rÃ©fÃ©rence
            $referenceType = [System.Nullable[int]]
            $referenceType | Should -Not -BeNullOrEmpty

            # Tester la fonction
            $nullableInt = New-NullableType -ValueType ([int])
            $nullableInt | Should -Not -BeNullOrEmpty
            # VÃ©rifier que le type est bien un nullable
            $nullableInt.IsGenericType | Should -Be $true
            $nullableInt.GetGenericTypeDefinition() | Should -Be ([System.Nullable`1])
        }

        It "Should not create nullable types for reference types" {
            { New-NullableType -ValueType ([string]) } | Should -Throw
        }
    }

    Context "Type member functions" {
        It "Should get members of a type" {
            $members = Get-TypeMembers -Type ([System.String])
            $members | Should -Not -BeNullOrEmpty
            $members.Count | Should -BeGreaterThan 0
        }

        It "Should filter members by type" {
            $properties = Get-TypeMembers -Type ([System.String]) -MemberTypes Property
            $properties | Should -Not -BeNullOrEmpty
            $properties | ForEach-Object { $_.MemberType | Should -Be "Property" }
        }

        It "Should get members recursively" {
            $members = Get-TypeMembersRecursive -Type ([System.ArgumentException])
            $members | Should -Not -BeNullOrEmpty
            $members.Count | Should -BeGreaterThan 0
        }

        It "Should get members by category" {
            $membersByCategory = Get-TypeMembersByCategory -Type ([System.String])
            $membersByCategory | Should -Not -BeNullOrEmpty
            $membersByCategory.Keys | Should -Contain "Property"
            $membersByCategory.Keys | Should -Contain "Method"
        }
    }

    Context "Member filtering functions" {
        It "Should filter members by attribute" -Skip {
            # Utiliser un type qui a des attributs connus
            $attributeType = [System.AttributeUsageAttribute]
            $attributeMembers = Get-TypeMembersByAttribute -Type $attributeType -AttributeType ([System.ObsoleteAttribute])
            # Si aucun membre n'a cet attribut, vÃ©rifions au moins que la fonction s'exÃ©cute sans erreur
            $attributeMembers | Should -Not -BeNull
        }

        It "Should filter members by return type" {
            $stringMembers = Get-TypeMembersByReturnType -Type ([System.Object]) -ReturnType ([string])
            $stringMembers | Should -Not -BeNullOrEmpty
            $stringMembers | ForEach-Object {
                if ($_.MemberType -eq "Property") {
                    $_.PropertyType.FullName | Should -Be "System.String"
                } elseif ($_.MemberType -eq "Method") {
                    $_.ReturnType.FullName | Should -Be "System.String"
                }
            }
        }

        It "Should filter members by accessibility" {
            $publicMembers = Get-TypeMembersByAccessibility -Type ([System.String]) -Accessibility "Public"
            $publicMembers | Should -Not -BeNullOrEmpty
        }
    }

    Context "Special class analysis functions" {
        It "Should analyze exception types" {
            $exceptionInfo = Get-ExceptionTypeInfo -ExceptionType ([System.ArgumentException])
            $exceptionInfo | Should -Not -BeNullOrEmpty
            $exceptionInfo.FullName | Should -Be "System.ArgumentException"
            $exceptionInfo.Properties | Should -Not -BeNullOrEmpty
            $exceptionInfo.InheritanceHierarchy | Should -Not -BeNullOrEmpty
        }

        It "Should analyze attribute types" {
            $attributeInfo = Get-AttributeTypeInfo -AttributeType ([System.SerializableAttribute])
            $attributeInfo | Should -Not -BeNullOrEmpty
            $attributeInfo.FullName | Should -Be "System.SerializableAttribute"
            $attributeInfo.ValidTargets | Should -Not -BeNullOrEmpty
        }

        It "Should analyze enum types" {
            $enumInfo = Get-EnumTypeInfo -EnumType ([System.DayOfWeek])
            $enumInfo | Should -Not -BeNullOrEmpty
            $enumInfo.FullName | Should -Be "System.DayOfWeek"
            $enumInfo.Values | Should -Not -BeNullOrEmpty
            $enumInfo.Values.Count | Should -Be 7  # 7 jours dans une semaine
        }
    }
}

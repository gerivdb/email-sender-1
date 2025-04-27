BeforeAll {
    # Importer le module Ã  tester
    . $PSScriptRoot/property_identification.ps1
}

Describe "Fonctions d'identification des propriÃ©tÃ©s" {
    Context "DÃ©tection des accesseurs" {
        It "Should detect property accessors" {
            $propertyInfo = [System.String].GetProperty("Length")
            $accessors = Get-PropertyAccessors -Property $propertyInfo
            
            $accessors | Should -Not -BeNullOrEmpty
            $accessors.HasGetter | Should -Be $true
            $accessors.HasSetter | Should -Be $false
            $accessors.IsReadOnly | Should -Be $true
            $accessors.IsWriteOnly | Should -Be $false
        }
        
        It "Should create property accessor map" {
            $accessorMap = Get-TypePropertyAccessorMap -Type ([System.String])
            
            $accessorMap | Should -Not -BeNullOrEmpty
            $accessorMap.Keys.Count | Should -BeGreaterThan 0
            $accessorMap["Length"] | Should -Not -BeNullOrEmpty
            $accessorMap["Length"].IsReadOnly | Should -Be $true
        }
        
        It "Should test property accessor type compatibility" {
            $propertyInfo = [System.String].GetProperty("Length")
            $compatibility = Test-PropertyAccessorTypeCompatibility -Property $propertyInfo
            
            $compatibility | Should -Not -BeNullOrEmpty
            $compatibility.IsCompatible | Should -Be $true
        }
        
        It "Should detect explicit interface accessors" {
            # Utiliser une classe qui implÃ©mente explicitement une interface
            $listType = [System.Collections.Generic.List`1[System.String]]
            $explicitAccessors = Get-TypeExplicitInterfaceAccessors -Type $listType
            
            $explicitAccessors | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "VÃ©rification des niveaux d'accÃ¨s" {
        It "Should get property access levels" {
            $propertyInfo = [System.String].GetProperty("Length")
            $accessLevels = Get-PropertyAccessLevels -Property $propertyInfo
            
            $accessLevels | Should -Not -BeNullOrEmpty
            $accessLevels.PropertyAccess | Should -Be "Public"
            $accessLevels.IsPublic | Should -Be $true
        }
        
        It "Should detect asymmetric accessors" {
            # CrÃ©er une classe avec des accesseurs asymÃ©triques pour le test
            $code = @"
            public class TestClass {
                private string _name;
                public string Name { get { return _name; } private set { _name = value; } }
            }
"@
            Add-Type -TypeDefinition $code -Language CSharp
            
            $asymmetricAccessors = Get-TypeAsymmetricAccessors -Type ([TestClass])
            
            $asymmetricAccessors | Should -Not -BeNullOrEmpty
            $asymmetricAccessors[0].HasAsymmetricAccessors | Should -Be $true
        }
        
        It "Should test property access restrictions" {
            $propertyInfo = [System.String].GetProperty("Length")
            $restrictions = Test-PropertyAccessRestrictions -Property $propertyInfo
            
            $restrictions | Should -Not -BeNullOrEmpty
        }
        
        It "Should get mixed access properties" {
            # CrÃ©er une classe avec des propriÃ©tÃ©s Ã  accÃ¨s mixte pour le test
            $code = @"
            public class TestClassMixed {
                private string _name;
                private int _age;
                
                public string Name { get { return _name; } private set { _name = value; } }
                public int Age { get { return _age; } set { _age = value; } }
            }
"@
            Add-Type -TypeDefinition $code -Language CSharp
            
            $mixedAccessProperties = Get-TypeMixedAccessProperties -Type ([TestClassMixed])
            
            $mixedAccessProperties | Should -Not -BeNullOrEmpty
            $mixedAccessProperties[0].IsMixed | Should -Be $true
        }
    }
    
    Context "Analyse des attributs" {
        It "Should detect serialization attributes" {
            # CrÃ©er une classe avec des attributs de sÃ©rialisation pour le test
            $code = @"
            using System;
            using System.Xml.Serialization;
            
            [Serializable]
            public class TestSerializable {
                [XmlElement("Name")]
                public string Name { get; set; }
                
                [XmlIgnore]
                public int Age { get; set; }
            }
"@
            Add-Type -TypeDefinition $code -Language CSharp
            
            $propertyInfo = [TestSerializable].GetProperty("Name")
            $serializationAttributes = Get-PropertySerializationAttributes -Property $propertyInfo
            
            $serializationAttributes | Should -Not -BeNullOrEmpty
            $serializationAttributes.HasSerializationAttributes | Should -Be $true
            $serializationAttributes.XmlAttributes.Count | Should -BeGreaterThan 0
        }
        
        It "Should analyze validation attributes" {
            # CrÃ©er une classe avec des attributs de validation pour le test
            $code = @"
            using System;
            using System.ComponentModel.DataAnnotations;
            
            public class TestValidation {
                [Required]
                [StringLength(50)]
                public string Name { get; set; }
                
                [Range(0, 120)]
                public int Age { get; set; }
            }
"@
            Add-Type -TypeDefinition $code -Language CSharp
            
            $propertyInfo = [TestValidation].GetProperty("Name")
            $validationAttributes = Get-PropertyValidationAttributes -Property $propertyInfo
            
            $validationAttributes | Should -Not -BeNullOrEmpty
            $validationAttributes.HasValidationAttributes | Should -Be $true
            $validationAttributes.IsRequired | Should -Be $true
            $validationAttributes.HasStringLengthValidation | Should -Be $true
        }
        
        It "Should process custom attributes" {
            # CrÃ©er une classe avec des attributs personnalisÃ©s pour le test
            $code = @"
            using System;
            
            [AttributeUsage(AttributeTargets.Property)]
            public class CustomAttribute : Attribute {
                public string Description { get; set; }
                
                public CustomAttribute(string description) {
                    Description = description;
                }
            }
            
            public class TestCustomAttributes {
                [Custom("Test description")]
                public string Name { get; set; }
            }
"@
            Add-Type -TypeDefinition $code -Language CSharp
            
            $propertyInfo = [TestCustomAttributes].GetProperty("Name")
            $customAttributes = Get-PropertyCustomAttributes -Property $propertyInfo
            
            $customAttributes | Should -Not -BeNullOrEmpty
            $customAttributes[0].AttributeType.Name | Should -Be "CustomAttribute"
            $customAttributes[0].PropertyValues["Description"] | Should -Be "Test description"
        }
        
        It "Should categorize properties by attributes" {
            # Utiliser la classe de test avec diffÃ©rents attributs
            $categorizedProperties = Get-TypePropertiesByAttributes -Type ([TestSerializable])
            
            $categorizedProperties | Should -Not -BeNullOrEmpty
            $categorizedProperties.SerializableProperties.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "PropriÃ©tÃ©s auto-implÃ©mentÃ©es" {
        BeforeAll {
            # CrÃ©er des classes de test avec diffÃ©rents types de propriÃ©tÃ©s
            $code = @"
            using System;
            using System.Runtime.CompilerServices;
            
            public class TestAutoImplemented {
                // PropriÃ©tÃ© auto-implÃ©mentÃ©e
                public string Name { get; set; }
                
                // PropriÃ©tÃ© explicite
                private int _age;
                public int Age {
                    get { return _age; }
                    set { _age = value; }
                }
                
                // PropriÃ©tÃ© en lecture seule
                public string Id { get; } = Guid.NewGuid().ToString();
                
                // PropriÃ©tÃ© avec attribut d'inlining
                private bool _active;
                public bool Active {
                    [MethodImpl(MethodImplOptions.AggressiveInlining)]
                    get { return _active; }
                    set { _active = value; }
                }
            }
"@
            Add-Type -TypeDefinition $code -Language CSharp
        }
        
        It "Should detect backing fields" {
            $backingFields = Get-TypePropertyBackingFields -Type ([TestAutoImplemented])
            
            $backingFields | Should -Not -BeNullOrEmpty
            $backingFields.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier qu'au moins une propriÃ©tÃ© auto-implÃ©mentÃ©e est dÃ©tectÃ©e
            $autoImplemented = $backingFields | Where-Object { $_.IsAutoImplemented }
            $autoImplemented | Should -Not -BeNullOrEmpty
        }
        
        It "Should identify synthetic properties" {
            $syntheticProperties = Get-TypeSyntheticProperties -Type ([TestAutoImplemented])
            
            $syntheticProperties | Should -Not -BeNullOrEmpty
        }
        
        It "Should distinguish property implementation types" {
            $implementationTypes = Get-TypePropertyImplementationTypes -Type ([TestAutoImplemented])
            
            $implementationTypes | Should -Not -BeNullOrEmpty
            $implementationTypes.AutoImplementedProperties.Count | Should -BeGreaterThan 0
            $implementationTypes.ExplicitProperties.Count | Should -BeGreaterThan 0
        }
        
        It "Should analyze compiler optimizations" {
            $optimizations = Get-TypePropertyCompilerOptimizations -Type ([TestAutoImplemented])
            
            $optimizations | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier qu'au moins une propriÃ©tÃ© avec AggressiveInlining est dÃ©tectÃ©e
            $inlinedProperty = $optimizations | Where-Object { $_.HasAggressiveInlining }
            $inlinedProperty | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier qu'au moins une propriÃ©tÃ© en lecture seule est dÃ©tectÃ©e
            $readOnlyProperty = $optimizations | Where-Object { $_.IsReadOnly }
            $readOnlyProperty | Should -Not -BeNullOrEmpty
        }
    }
}

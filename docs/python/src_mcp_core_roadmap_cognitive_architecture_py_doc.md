Help on module cognitive_architecture:

NAME
    cognitive_architecture - Module pour l'architecture cognitive des roadmaps.

DESCRIPTION
    Ce module contient les classes et fonctions pour impl�menter l'architecture cognitive
    des roadmaps, avec un mod�le hi�rarchique � 10 niveaux.

CLASSES
    builtins.object
        CognitiveNode
            Building
            City
            Continent
            Cosmos
            District
            Galaxy
            Planet
            Region
            StellarSystem
            Street
    enum.Enum(builtins.object)
        HierarchyLevel
        NodeStatus

    class Building(CognitiveNode)
     |  Building(name: str, street_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |
     |  Classe repr�sentant le niveau BATIMENTS de l'architecture cognitive.
     |
     |  Un BATIMENT repr�sente un �l�ment de base (variable, constante, etc.).
     |
     |  Method resolution order:
     |      Building
     |      CognitiveNode
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, street_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |      Initialise un n�ud BATIMENT.
     |
     |      Args:
     |          name (str): Nom du BATIMENT
     |          street_id (str): Identifiant de la RUE parente
     |          description (str, optional): Description du BATIMENT. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant du BATIMENT. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es du BATIMENT. Par d�faut None.
     |          status (NodeStatus, optional): Statut du BATIMENT. Par d�faut NodeStatus.PLANNED.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from CognitiveNode:
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from CognitiveNode:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveNode:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class City(CognitiveNode)
     |  City(name: str, region_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |
     |  Classe repr�sentant le niveau VILLES de l'architecture cognitive.
     |
     |  Une VILLE repr�sente un composant ou un service.
     |
     |  Method resolution order:
     |      City
     |      CognitiveNode
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, region_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |      Initialise un n�ud VILLE.
     |
     |      Args:
     |          name (str): Nom de la VILLE
     |          region_id (str): Identifiant de la REGION parente
     |          description (str, optional): Description de la VILLE. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant de la VILLE. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es de la VILLE. Par d�faut None.
     |          status (NodeStatus, optional): Statut de la VILLE. Par d�faut NodeStatus.PLANNED.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from CognitiveNode:
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from CognitiveNode:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveNode:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class CognitiveNode(builtins.object)
     |  CognitiveNode(name: str, level: cognitive_architecture.HierarchyLevel, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>, parent_id: Optional[str] = None)
     |
     |  Classe de base pour tous les n�uds de l'architecture cognitive.
     |
     |  Un n�ud repr�sente un �l�ment � n'importe quel niveau de la hi�rarchie.
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, level: cognitive_architecture.HierarchyLevel, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>, parent_id: Optional[str] = None)
     |      Initialise un n�ud cognitif.
     |
     |      Args:
     |          name (str): Nom du n�ud
     |          level (HierarchyLevel): Niveau hi�rarchique du n�ud
     |          description (str, optional): Description du n�ud. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant du n�ud. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es du n�ud. Par d�faut None.
     |          status (NodeStatus, optional): Statut du n�ud. Par d�faut NodeStatus.PLANNED.
     |          parent_id (Optional[str], optional): Identifiant du n�ud parent. Par d�faut None.
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class Continent(CognitiveNode)
     |  Continent(name: str, planet_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |
     |  Classe repr�sentant le niveau CONTINENTS de l'architecture cognitive.
     |
     |  Un CONTINENT repr�sente une grande fonctionnalit� ou un module.
     |
     |  Method resolution order:
     |      Continent
     |      CognitiveNode
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, planet_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |      Initialise un n�ud CONTINENT.
     |
     |      Args:
     |          name (str): Nom du CONTINENT
     |          planet_id (str): Identifiant de la PLANETE parente
     |          description (str, optional): Description du CONTINENT. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant du CONTINENT. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es du CONTINENT. Par d�faut None.
     |          status (NodeStatus, optional): Statut du CONTINENT. Par d�faut NodeStatus.PLANNED.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from CognitiveNode:
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from CognitiveNode:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveNode:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class Cosmos(CognitiveNode)
     |  Cosmos(name: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |
     |  Classe repr�sentant le niveau COSMOS de l'architecture cognitive.
     |
     |  Le COSMOS est le niveau le plus �lev�, repr�sentant la vision globale du syst�me.
     |
     |  Method resolution order:
     |      Cosmos
     |      CognitiveNode
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |      Initialise un n�ud COSMOS.
     |
     |      Args:
     |          name (str): Nom du COSMOS
     |          description (str, optional): Description du COSMOS. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant du COSMOS. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es du COSMOS. Par d�faut None.
     |          status (NodeStatus, optional): Statut du COSMOS. Par d�faut NodeStatus.PLANNED.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from CognitiveNode:
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from CognitiveNode:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveNode:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class District(CognitiveNode)
     |  District(name: str, city_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |
     |  Classe repr�sentant le niveau QUARTIERS de l'architecture cognitive.
     |
     |  Un QUARTIER repr�sente un sous-composant.
     |
     |  Method resolution order:
     |      District
     |      CognitiveNode
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, city_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |      Initialise un n�ud QUARTIER.
     |
     |      Args:
     |          name (str): Nom du QUARTIER
     |          city_id (str): Identifiant de la VILLE parente
     |          description (str, optional): Description du QUARTIER. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant du QUARTIER. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es du QUARTIER. Par d�faut None.
     |          status (NodeStatus, optional): Statut du QUARTIER. Par d�faut NodeStatus.PLANNED.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from CognitiveNode:
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from CognitiveNode:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveNode:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class Galaxy(CognitiveNode)
     |  Galaxy(name: str, cosmos_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |
     |  Classe repr�sentant le niveau GALAXIES de l'architecture cognitive.
     |
     |  Une GALAXIE repr�sente un grand domaine ou th�me du syst�me.
     |
     |  Method resolution order:
     |      Galaxy
     |      CognitiveNode
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, cosmos_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |      Initialise un n�ud GALAXIE.
     |
     |      Args:
     |          name (str): Nom de la GALAXIE
     |          cosmos_id (str): Identifiant du COSMOS parent
     |          description (str, optional): Description de la GALAXIE. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant de la GALAXIE. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es de la GALAXIE. Par d�faut None.
     |          status (NodeStatus, optional): Statut de la GALAXIE. Par d�faut NodeStatus.PLANNED.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from CognitiveNode:
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from CognitiveNode:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveNode:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class HierarchyLevel(enum.Enum)
     |  HierarchyLevel(*values)
     |
     |  �num�ration des niveaux hi�rarchiques de l'architecture cognitive.
     |
     |  Method resolution order:
     |      HierarchyLevel
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  BATIMENTS = <HierarchyLevel.BATIMENTS: 10>
     |
     |  CONTINENTS = <HierarchyLevel.CONTINENTS: 5>
     |
     |  COSMOS = <HierarchyLevel.COSMOS: 1>
     |
     |  GALAXIES = <HierarchyLevel.GALAXIES: 2>
     |
     |  PLANETES = <HierarchyLevel.PLANETES: 4>
     |
     |  QUARTIERS = <HierarchyLevel.QUARTIERS: 8>
     |
     |  REGIONS = <HierarchyLevel.REGIONS: 6>
     |
     |  RUES = <HierarchyLevel.RUES: 9>
     |
     |  SYSTEMES = <HierarchyLevel.SYSTEMES: 3>
     |
     |  VILLES = <HierarchyLevel.VILLES: 7>
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from enum.Enum:
     |
     |  name
     |      The name of the Enum member.
     |
     |  value
     |      The value of the Enum member.
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

    class NodeStatus(enum.Enum)
     |  NodeStatus(*values)
     |
     |  �num�ration des statuts possibles pour un n�ud.
     |
     |  Method resolution order:
     |      NodeStatus
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  BLOCKED = <NodeStatus.BLOCKED: 4>
     |
     |  COMPLETED = <NodeStatus.COMPLETED: 3>
     |
     |  DEPRECATED = <NodeStatus.DEPRECATED: 5>
     |
     |  IN_PROGRESS = <NodeStatus.IN_PROGRESS: 2>
     |
     |  PLANNED = <NodeStatus.PLANNED: 1>
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from enum.Enum:
     |
     |  name
     |      The name of the Enum member.
     |
     |  value
     |      The value of the Enum member.
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

    class Planet(CognitiveNode)
     |  Planet(name: str, system_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |
     |  Classe repr�sentant le niveau PLANETES de l'architecture cognitive.
     |
     |  Une PLANETE repr�sente un projet individuel.
     |
     |  Method resolution order:
     |      Planet
     |      CognitiveNode
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, system_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |      Initialise un n�ud PLANETE.
     |
     |      Args:
     |          name (str): Nom de la PLANETE
     |          system_id (str): Identifiant du SYSTEME STELLAIRE parent
     |          description (str, optional): Description de la PLANETE. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant de la PLANETE. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es de la PLANETE. Par d�faut None.
     |          status (NodeStatus, optional): Statut de la PLANETE. Par d�faut NodeStatus.PLANNED.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from CognitiveNode:
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from CognitiveNode:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveNode:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class Region(CognitiveNode)
     |  Region(name: str, continent_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |
     |  Classe repr�sentant le niveau REGIONS de l'architecture cognitive.
     |
     |  Une REGION repr�sente une fonctionnalit� sp�cifique.
     |
     |  Method resolution order:
     |      Region
     |      CognitiveNode
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, continent_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |      Initialise un n�ud REGION.
     |
     |      Args:
     |          name (str): Nom de la REGION
     |          continent_id (str): Identifiant du CONTINENT parent
     |          description (str, optional): Description de la REGION. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant de la REGION. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es de la REGION. Par d�faut None.
     |          status (NodeStatus, optional): Statut de la REGION. Par d�faut NodeStatus.PLANNED.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from CognitiveNode:
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from CognitiveNode:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveNode:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class StellarSystem(CognitiveNode)
     |  StellarSystem(name: str, galaxy_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |
     |  Classe repr�sentant le niveau SYSTEMES STELLAIRES de l'architecture cognitive.
     |
     |  Un SYSTEME STELLAIRE repr�sente un groupe de projets li�s.
     |
     |  Method resolution order:
     |      StellarSystem
     |      CognitiveNode
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, galaxy_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |      Initialise un n�ud SYSTEME STELLAIRE.
     |
     |      Args:
     |          name (str): Nom du SYSTEME STELLAIRE
     |          galaxy_id (str): Identifiant de la GALAXIE parente
     |          description (str, optional): Description du SYSTEME STELLAIRE. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant du SYSTEME STELLAIRE. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es du SYSTEME STELLAIRE. Par d�faut None.
     |          status (NodeStatus, optional): Statut du SYSTEME STELLAIRE. Par d�faut NodeStatus.PLANNED.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from CognitiveNode:
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from CognitiveNode:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveNode:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class Street(CognitiveNode)
     |  Street(name: str, district_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |
     |  Classe repr�sentant le niveau RUES de l'architecture cognitive.
     |
     |  Une RUE repr�sente une classe ou une fonction.
     |
     |  Method resolution order:
     |      Street
     |      CognitiveNode
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, district_id: str, description: str = '', node_id: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, status: cognitive_architecture.NodeStatus = <NodeStatus.PLANNED: 1>)
     |      Initialise un n�ud RUE.
     |
     |      Args:
     |          name (str): Nom de la RUE
     |          district_id (str): Identifiant du QUARTIER parent
     |          description (str, optional): Description de la RUE. Par d�faut "".
     |          node_id (Optional[str], optional): Identifiant de la RUE. Si None, un UUID est g�n�r�.
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es de la RUE. Par d�faut None.
     |          status (NodeStatus, optional): Statut de la RUE. Par d�faut NodeStatus.PLANNED.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from CognitiveNode:
     |
     |  add_child(self, child_id: str) -> None
     |      Ajoute un enfant au n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � ajouter
     |
     |  remove_child(self, child_id: str) -> bool
     |      Supprime un enfant du n�ud.
     |
     |      Args:
     |          child_id (str): Identifiant de l'enfant � supprimer
     |
     |      Returns:
     |          bool: True si l'enfant a �t� supprim�, False sinon
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le n�ud en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant le n�ud
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es du n�ud.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  update_status(self, status: cognitive_architecture.NodeStatus) -> None
     |      Met � jour le statut du n�ud.
     |
     |      Args:
     |          status (NodeStatus): Nouveau statut
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from CognitiveNode:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CognitiveNode'
     |      Cr�e un n�ud � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant le n�ud
     |
     |      Returns:
     |          CognitiveNode: Instance de n�ud
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveNode:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

DATA
    Dict = typing.Dict
        A generic version of dict.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Set = typing.Set
        A generic version of set.

    logger = <Logger mcp.core.roadmap.cognitive_architecture (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\roadmap\cognitive_architecture.py



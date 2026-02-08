# StarUML Class Diagram Guide - Indoor Navigation System

## 📋 Overview
This guide will help you create a comprehensive **Class Diagram** for the Indoor Navigation System using StarUML. The diagram will illustrate the system's architecture, including entities, services, and their relationships.

---

## 🎯 What We'll Model

**System Architecture Components:**
- **Domain Entities**: Building, Floor, Room, Corridor, UserEntity
- **Services**: PathfindingService
- **Enumerations**: RoomType, UserRole
- **Relationships**: Associations, Compositions, Dependencies
- **Clean Architecture Layers**: Domain, Data, Presentation

---

## 🛠 Prerequisites

1. **StarUML installed** from https://staruml.io/
2. **Understanding of your codebase** structure
3. **Basic UML Class Diagram concepts**

---

## 📐 Step-by-Step Instructions

### Step 1: Create New Project
1. Open **StarUML**
2. Click **File → New**
3. Select **UML Standard** from templates
4. Click **OK**

### Step 2: Add Class Diagram
1. In the **Model Explorer** (left panel), right-click on **Model**
2. Select **Add Diagram → Class Diagram**
3. Rename it to `IndoorNavigationClassDiagram`

---

### Step 3: Create Packages (Optional but Recommended)

Organize classes by architectural layers:

1. Click **Package** tool in toolbar
2. Create these packages on canvas:
   - **Domain** (for entities)
   - **Services** (for business logic)
   - **Enums** (for enumerations)

**Layout**: Arrange packages horizontally or vertically

---

### Step 4: Add Enumeration Classes

#### Enum 1: RoomType
1. Click **Enumeration** tool (or Class → change stereotype to «enumeration»)
2. Place in **Enums** package
3. Name it `RoomType`
4. Add **Literals** (right-click → Add → Enumeration Literal):
   - `room`
   - `hallway`
   - `stairs`
   - `elevator`
   - `entrance`
   - `restroom`
   - `cafeteria`
   - `lab`
   - `library`
   - `parking`
   - `ground`
   - `office`

#### Enum 2: UserRole
1. Create another **Enumeration**
2. Name it `UserRole`
3. Add literals:
   - `admin`
   - `user`

---

### Step 5: Add Entity Classes

#### Class 1: Building
1. Click **Class** tool
2. Place in **Domain** package
3. Name it `Building`
4. Add **Attributes** (click + icon or right-click → Add → Attribute):
   - `- id: String`
   - `- name: String`
   - `- description: String`
   - `- organizationId: String?`
   - `- northOffset: double`
5. Add **Methods**:
   - `+ Building(id, name, description, organizationId, northOffset)`
   - `+ props: List<Object?>`

**Visibility**:
- `-` = private
- `+` = public
- `#` = protected

#### Class 2: Floor
1. Create **Class** named `Floor`
2. Add attributes:
   - `- id: String`
   - `- buildingId: String`
   - `- floorNumber: int`
   - `- name: String`
3. Add methods:
   - `+ Floor(id, buildingId, floorNumber, name)`
   - `+ props: List<Object>`

#### Class 3: Room
1. Create **Class** named `Room`
2. Add attributes:
   - `- id: String`
   - `- floorId: String`
   - `- name: String`
   - `- x: double`
   - `- y: double`
   - `- type: RoomType`
   - `- connectorId: String?`
3. Add methods:
   - `+ Room(id, floorId, name, x, y, type, connectorId)`
   - `+ props: List<Object?>`

#### Class 4: Corridor
1. Create **Class** named `Corridor`
2. Add attributes:
   - `- id: String`
   - `- floorId: String`
   - `- startRoomId: String`
   - `- endRoomId: String`
   - `- distance: double`
3. Add methods:
   - `+ Corridor(id, floorId, startRoomId, endRoomId, distance)`
   - `+ props: List<Object>`

#### Class 5: UserEntity
1. Create **Class** named `UserEntity`
2. Add attributes:
   - `- id: String`
   - `- email: String`
   - `- role: UserRole`
   - `- organizationId: String`
3. Add methods:
   - `+ UserEntity(id, email, role, organizationId)`
   - `+ props: List<Object>`

---

### Step 6: Add Service Classes

#### Class: PathfindingService
1. Create **Class** named `PathfindingService`
2. Add **stereotype** `«service»` (right-click → Stereotype → Add)
3. Add **static methods**:
   - `+ {static} findPath(startId: String, endId: String, rooms: List<Room>, corridors: List<Corridor>, isAccessible: bool): List<String>`
   - `- {static} _heuristic(a: Room, b: Room): double`
   - `- {static} _reconstructPath(cameFrom: Map<String,String>, current: String): List<String>`

**Note**: Use `{static}` property for static methods

---

### Step 7: Add Relationships

#### Association: Building → Floor (1 to many)
1. Click **Association** tool (or **Directed Association**)
2. Draw from `Building` to `Floor`
3. Set **multiplicity**:
   - Building end: `1`
   - Floor end: `0..*` (zero to many)
4. Label: `contains`

#### Association: Floor → Room (1 to many)
1. Draw **Association** from `Floor` to `Room`
2. Multiplicity:
   - Floor end: `1`
   - Room end: `0..*`
3. Label: `contains`

#### Association: Floor → Corridor (1 to many)
1. Draw **Association** from `Floor` to `Corridor`
2. Multiplicity:
   - Floor end: `1`
   - Corridor end: `0..*`
3. Label: `contains`

#### Association: Corridor → Room (many to 2)
1. Draw **Association** from `Corridor` to `Room`
2. Multiplicity:
   - Corridor end: `1`
   - Room end: `2` (start and end)
3. Label: `connects`
4. Add **role names**:
   - Near first Room: `startRoom`
   - Near second Room: `endRoom`

#### Dependency: Room → RoomType
1. Click **Dependency** tool (dashed arrow)
2. Draw from `Room` to `RoomType`
3. Label: `«uses»`

#### Dependency: UserEntity → UserRole
1. Draw **Dependency** from `UserEntity` to `UserRole`
2. Label: `«uses»`

#### Dependency: PathfindingService → Room
1. Draw **Dependency** from `PathfindingService` to `Room`
2. Label: `«uses»`

#### Dependency: PathfindingService → Corridor
1. Draw **Dependency** from `PathfindingService` to `Corridor`
2. Label: `«uses»`

---

### Step 8: Add Inheritance (if applicable)

If you have base classes like `Equatable`:

1. Create **Class** named `Equatable` (abstract)
2. Set as **abstract** (right-click → Properties → isAbstract = true)
3. Add method: `+ props: List<Object?>`
4. Click **Generalization** tool (solid line with hollow arrow)
5. Draw from each entity to `Equatable`:
   - `Building` → `Equatable`
   - `Floor` → `Equatable`
   - `Room` → `Equatable`
   - `Corridor` → `Equatable`
   - `UserEntity` → `Equatable`

---

### Step 9: Format and Style

#### Organize Layout
1. **Arrange classes** logically:
   - Top: Enumerations
   - Middle: Entities
   - Bottom: Services
2. Use **Format → Layout → Auto Layout** for automatic arrangement
3. Manually adjust for clarity

#### Color Coding
1. Select **Enumerations** → Format → Fill Color → Light Purple
2. Select **Entities** → Format → Fill Color → Light Blue
3. Select **Services** → Format → Fill Color → Light Green
4. Select **Abstract Classes** → Format → Fill Color → Light Gray

#### Alignment
1. Select multiple classes
2. Format → Align → Align Top/Center
3. Format → Align → Distribute Horizontally

---

### Step 10: Add Notes and Annotations

Add **Notes** to explain key concepts:

#### Note 1: A* Algorithm
```
Position: Near PathfindingService
Text: "Implements A* pathfinding algorithm
       - Supports multi-floor navigation
       - Accessibility mode (avoids stairs)
       - Heuristic: Euclidean distance"
```

#### Note 2: Clean Architecture
```
Position: Top of diagram
Text: "Domain Layer - Core Business Entities
       Independent of frameworks and UI"
```

---

### Step 11: Export Diagram

1. Click **File → Export Diagram**
2. Choose **PNG** format
3. Set resolution to **300 DPI**
4. Save as `ClassDiagram.png` in `/docs/diagrams/`

**Alternative**:
- **SVG** for vector graphics
- **PDF** for documentation

---

## 🎨 Diagram Best Practices

### Visual Clarity
- **Group related classes**: Keep entities together, services together
- **Minimize crossing lines**: Rearrange classes to reduce arrow crossings
- **Use consistent spacing**: Align classes in a grid pattern
- **Show only relevant details**: Don't include every getter/setter

### Naming Conventions
- **Classes**: PascalCase (`Building`, `PathfindingService`)
- **Attributes**: camelCase with type (`id: String`)
- **Methods**: camelCase with parameters and return type
- **Relationships**: Lowercase labels (`contains`, `uses`)

### Relationship Guidelines
- **Association**: Structural relationship (Building contains Floors)
- **Dependency**: Usage relationship (Service uses Entity)
- **Generalization**: Inheritance (Entity extends Equatable)
- **Composition**: Strong ownership (use filled diamond if needed)

---

## 📊 Key Elements Reference

| Element | StarUML Tool | Purpose | Example |
|---------|-------------|---------|---------|
| **Class** | Class | Entity or Service | `Building`, `PathfindingService` |
| **Enumeration** | Enumeration | Enum type | `RoomType`, `UserRole` |
| **Attribute** | Add Attribute | Class field | `- id: String` |
| **Method** | Add Operation | Class function | `+ findPath(...): List<String>` |
| **Association** | Association | Structural link | Building → Floor |
| **Dependency** | Dependency | Usage link | Service → Entity |
| **Generalization** | Generalization | Inheritance | Entity → Equatable |
| **Package** | Package | Grouping | Domain, Services |
| **Note** | Note | Annotation | Explain algorithms |

---

## 🔍 Class Details

### Building Class
```
┌─────────────────────────┐
│      Building           │
├─────────────────────────┤
│ - id: String            │
│ - name: String          │
│ - description: String   │
│ - organizationId: String?│
│ - northOffset: double   │
├─────────────────────────┤
│ + Building(...)         │
│ + props: List<Object?>  │
└─────────────────────────┘
```

### PathfindingService Class
```
┌──────────────────────────────────────┐
│   «service»                          │
│   PathfindingService                 │
├──────────────────────────────────────┤
│                                      │
├──────────────────────────────────────┤
│ + {static} findPath(...): List<String>│
│ - {static} _heuristic(...): double   │
│ - {static} _reconstructPath(...): List│
└──────────────────────────────────────┘
```

---

## ✅ Final Checklist

Before exporting:

- [ ] All entity classes are present (Building, Floor, Room, Corridor, UserEntity)
- [ ] All enumerations are included (RoomType, UserRole)
- [ ] PathfindingService class is added
- [ ] Attributes have correct visibility (-, +)
- [ ] Methods include parameters and return types
- [ ] Associations have multiplicity (1, 0..*, etc.)
- [ ] Dependencies are shown with dashed arrows
- [ ] Inheritance is shown (if using Equatable)
- [ ] Classes are properly organized and aligned
- [ ] Color coding is applied
- [ ] Notes explain key concepts
- [ ] Diagram is exported as high-resolution PNG

---

## 💡 Advanced Features (Optional)

### Composition vs Association
Use **Composition** (filled diamond) if:
- Floor cannot exist without Building
- Room cannot exist without Floor

Use **Association** (line) if:
- Entities can exist independently

### Interface Implementation
If you have interfaces:
1. Create **Interface** (right-click Class → Stereotype → «interface»)
2. Use **Realization** (dashed line with hollow arrow)

### Abstract Classes
Mark classes as abstract:
1. Right-click class → Properties
2. Set `isAbstract = true`
3. Class name will be italicized

---

## 🎓 Learning Resources

- **StarUML Class Diagram**: https://docs.staruml.io/working-with-diagrams/class-diagram
- **UML Class Diagrams**: https://www.uml-diagrams.org/class-diagrams-overview.html
- **Clean Architecture**: Organize by layers (Domain, Data, Presentation)

---

## 🚀 Quick Tips

1. **Start with entities**: Add all classes first, then relationships
2. **Use packages**: Group related classes for clarity
3. **Keep it simple**: Don't include every detail, focus on architecture
4. **Show key relationships**: Not every dependency needs to be shown
5. **Use stereotypes**: `«service»`, `«entity»`, `«enumeration»` for clarity

---

**Your Class Diagram will showcase the core architecture of your Indoor Navigation System! 📐**

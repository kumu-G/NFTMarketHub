# Comprehensive Solidity Style Guide

## Layout and Formatting

### Comment Formatting
Use the following format for section comments:
```solidity
///////////////////
// Section Name
///////////////////
```

### Function Spacing
- Within a contract, surround function declarations with a single blank line.

### Line Length
- Maximum suggested line length is 120 characters.

## Naming Conventions

### Contract and Library Names
- Use CapWords style (also known as PascalCase).
  Example: `MyContract`, `LibraryCoolFeature`

### Struct Names
- Use CapWords style.
  Example: `UserProfile`, `PaymentDetails`

### Event Names
- Use CapWords style.
  Example: `Transfer`, `Approval`

### Function Names
- Use mixedCase.
  Example: `getBalance`, `sendTokens`

### Function Argument Names
- Use mixedCase.
  Example: `initialSupply`, `account`

### Local and State Variable Names
- Use mixedCase.
  Example: `totalSupply`, `balanceOf`

### Constants
- Use capital letters with underscores separating words.
  Example: `MAX_SUPPLY`, `DECIMALS`

### Modifier Names
- Use mixedCase.
  Example: `onlyOwner`, `whenNotPaused`

### Enums
- Use CapWords style for the enum name, and all uppercase for the values.
  Example:
  ```solidity
  enum Status { PENDING, SHIPPED, ACCEPTED, REJECTED, CANCELED }
  ```

### Avoiding Naming Collisions
- Use `singleTrailingUnderscore_` when the desired name collides with an existing state variable, function, built-in, or otherwise reserved name.
  Example: `transfer_`

### Underscore Prefix for Non-external Functions and Variables
- Use `_singleLeadingUnderscore` for private functions and variables.
  Example: `_transfer`, `_totalSupply`

## Order of Layout

### Layout of Contract
1. Version
2. Imports
3. Errors
4. Interfaces, libraries, contracts
5. Type declarations
6. State variables
7. Events
8. Modifiers
9. Functions

### Layout of Functions
1. Constructor
2. Receive function (if exists)
3. Fallback function (if exists)
4. External functions
5. Public functions
6. Internal functions
7. Private functions
8. Internal & private view & pure functions
9. External & public view & pure functions

### Modifier Order
When defining a function, use the following order for modifiers:
1. Visibility
2. Mutability
3. Virtual
4. Override
5. Custom modifiers

Example:
```solidity
function foo() public payable virtual override onlyOwner returns (uint256) {
    // ...
}
```

## Error Naming Convention
```
contractname_errorname
```

## NatSpec Comments
Solidity contracts can contain NatSpec comments. They are written with a triple slash (///) or a double asterisk block (/** ... */) and should be used directly above function declarations or statements.

Example:
```solidity
/// @notice Transfers tokens from the caller to a recipient
/// @dev This function emits a Transfer event
/// @param recipient The address to receive the tokens
/// @param amount The number of tokens to transfer
/// @return A boolean indicating if the transfer was successful
function transfer(address recipient, uint256 amount) public returns (bool) {
    // Function implementation
}
```

## Example of Section Formatting
```solidity
///////////////////
// State Variables
///////////////////

uint256 public totalSupply;
mapping(address => uint256) private _balances;

///////////////////
// Events
///////////////////

event Transfer(address indexed from, address indexed to, uint256 value);

///////////////////
// Modifiers
///////////////////

modifier onlyOwner() {
    require(msg.sender == owner, "Not the owner");
    _;
}

///////////////////
// Functions
///////////////////

function transfer(address to, uint256 amount) public virtual returns (bool) {
    // Function implementation
}
```

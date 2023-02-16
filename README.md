# QuillCFT solutions
Here you can find the explainers I've submitted to QuillCTF, I find myself to be a little too verbose from time to time.

## TrueXOR
Make 2 consecutive staticcalls to the same function return different values: base the result off of remaining gas.

## Pelusa
The Pelusa contract presents several vulnerabilities, which put together make up a sort of
obsticle course an attacker must get through to achieve his goal.
The first vulnerability presented is the use of `msg.sender.code.length == 0` to verify wether
`msg.sender` is an EOA: this check doesn't achieve this check, given that a contract's codesize
is set only at the end of it's constructor's execution. This means that an attacker may bypass this
check by invoking the `passTheBall()` function from within his exploit contract, as I have in my
solution.
The second vulnerability is found at line 22, requiring for the sender's address to have a specified
result when interpreted as an integer and it's modulo 100 is calculated. In combination with the
vulnerability found above, it becomes obvious that an attacker must come up with a way to deploy a
contract whose address passes this check: I've accomplished this by brute-forcing the salt given to
create2 when determinstically deploying a contract.
A third vulnerability comes from the fact that Pelusa's `owner` field may easily be reconstructed
by an attacker: anyone is able to view who deployed the contract and at which block, thus recovering
the required address to be returned in the `isGoal()` view function. In my solution, I've carried
out all operations within the same block, whilst in a real life scenario, an attacker will have
to look up the preimage of the keccak256 hash, as cited above.
The final vulnerability comes from the delegatecall at line 35, in which execution is handed
to an arbitrary address, that is able to modify the Pelusa contract's state.
In particular, this allows an attacker to achieve his goal of modifying the `goal` state variable
from 1 to 2, by:

1. Creating a state variable in his exploit contract which will be delegatecalled to (note that
the collision happens at slot 1, as `owner` state variable does not occupy a storage slot)
2. Implementing the `handOfGod()` function to overwrite such storage slot and return the necessary
bytes32 to pass the require statement at line 37.

## WETH10
The challenge's contract WETH10 presents the major flaw of not following the checks-effects-interactions
pattern. Implementing a ReentrancyGuard and assigning the nonReentrant modifier to all external funcitons
achieves the goal of protecting the contract from a reentrancy attack which takes advantage
of incomplete state updates, but it does so only for calls to it's own functions.

The exploit I present takes advantage of the withdrawAll function, which first sends the sender's
WETH10 balance in ETH to the caller, and later burns the caller's shares.
By using a contract which implements a receive() function, within this function we can transfer
the contract's WETH10 tokens to a 3rd address (in this case, bob) so that _burnAll() will
not be able to burn the tokens it is meant to burn, as balanceOf(msg.sender) evaluates to 0.
Subsequently, after withdrawAll() has terminated it's execution, the exploit contract is able to
pull back the WETH10 tokens that should've been burned and is able to repeat the process,
draining the WETH10 contract of it's ETH balance.
This flow is implemented in the exploit contract's attack() function.

## Gate
Challenge still active 😜

## PandaToken
Challenge still active 😜
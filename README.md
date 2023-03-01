# QuillCFT solutions
Here you can find the explainers I've submitted to QuillCTF, I find myself to be a little too verbose from time to time.
If you want to chat about smart contract security let's chat on discord: ljmanini#1907

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
The Gate contract presents a set of require statements that form a set of obstacles an attacker must pass in order to achieve his goal of settings `opened` to true.
The first obstacle is very straight forward: achieve your goal by employing a contract whose code size doesn't exceed 32 bytes. I manage to solve the challenge using exactly 32 bytes.
The second obstacle comes in the form that, when the Gate contract invokes `guardian` with function selector equal to 0x00000000 (as may be found employing `cast sig "f00000000_bvvvdlt()"`), the Gate contract expects to be returned with it's own address.
Obstacle number 3 is similar to the second, with the difference that when using 0x00000001 as a selector, it expects to be returned the `tx.origin` address.
Finally, the fourth obstacle is that the Gate contract expects a call to `guardian` to fail, when invoking its `fail()` method.

I've managed to solve this CTF through a number of tricks:

1. Throughout all of my bytecode, I've employed CALLVALUE as if it were PUSH1 0, effectively occupying only 1 byte of code instead of 2.
2. I've optimized the 2 cases in which Gate calls the exploit contract with selectors 0 and 1 in that, CALLER and ORIGIN are pushed to the stack in separate locations of the code, but the function prologue in which these values are stored in memory are returned is the same used by both branches.
3. To guarantee that a call to "fail()" returns false as it's success value, I created the circumstances to voluntarily generate a StackUnderflow EVM error, so that obstacle 4 is cleared and the challenge is completed.

As a smaller note, to be able to do a PUSH1 1 in a single byte, I've used the CHAINID operation, implying that my solution would only work on Ethereum mainnet.

## PandaToken

The PandaToken contract implements a standard ERC20 token with a special functionality:
users are able to asynchronously send tokens by signing a message which specifies the receiver and the amount of tokens to be transferred: when a receiver calls this function
with a valid signature, the tokens are minted to his address and the same amount of tokens are saved to be burned from the sender's address.
The vulnerable function in this case is the `getTokens(uint, bytes)` function.
At first, it calculates the amount of tokens to be minted to the receiver, using the `calculateAmount(uint)` function which, upon close inspection, is found to simply return the amount passed as a parameter.
After that, the `getTokens()` function decomposes the received signature in it's v, r, s fields and tries to verify it against the message formed by msg.sender and the tokens to be minted.
Here lies the contract's vulnerability: when executing `ecrecover()`, if a signature fails to be verified, the returned address is the zero address. In this contract, this case is not checked for (e.g. using `require(giftFrom != address(0))`).
This issue, in combination with the fact address(0) is given 10 PND by executing the PandaToken constructor (as is understandable from the first 5 lines in the PandaToken constructor),allows an attacker to submit a malformed signature, which will assign `giftFrom = address(0)`, which in turn will pass `getTokens()`'s second require statement which checks `balanceOf(giftFrom)`.
Given that used signatures are saved in the contract's state so that they are not replayed, an attacker needs to build 3 malicious signatures, each extracting 1e18 PND tokens.
At the end, the attacker is able to achieve his goal of having 3e18 PND.

## WETH11
Challenge still active 😜

# Prime Casino Contracts
At the Prime Casino one can bet on whether a number is probably prime or not under the Miller-Rabin test.
A bet takes 0.1 ETH. one can either propose a new probably prime or stake yes/no on an existing one.


## PrimeCasino.sol

The client contract implementation for Enforcer.

### request

Request a new `canditateNumber` to be checked for primality.

### bet

Adds a new yes/no bet as `isPrime` on `canditateNumber`.

### getStatus

takes a potential prime number and returns `challengeEndTime` and array name `pathRoots`.


|                       | challengeEndTime > now                                             | challengeEndTime <= now && challengeEndTime > 0                       | challengeEndTime == 0 |
|-----------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------|-----------------------|
| pathRoots.length == 0 | no computation result registered yet. initial state after request. | computation market could not deliver any solution to given task.      | not requested         |
| pathRoots.length == 1 | first result registered. open for challenges.                      | exactly 1 result found. result can be used.                           | not requested         |
| pathRoots.length > 1  | some existing result challenged. cDance in progress.               | more than one result survived the cDance, computation market failed.  | not requested         |

### payout

Pays out `msg.sender` on `canditateNumber`.


## EnforcerMock.sol

A mock simulating the computation market.

### registerResult

Registers a result under a specific taskHash. the result is a bytes array. The taskHash is calculated from the computation request and can be read from `NewCandidatePrime` event in PrimeCasino.sol.

### finalizeTask

This sets a task to completed by setting `challengeEndTime` to `now -1`.

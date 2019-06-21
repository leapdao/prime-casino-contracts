# Prime Casino Contracts
At the Prime Casino one can bet on whether a number is probably prime or not under the Miller-Rabin test.
A bet takes 0.1 ETH. one can either propose a new probably prime or stake yes/no on an existing one.


## about `getStatus()`:

|                       | challengeEndTime > now                                             | challengeEndTime <= now                                               |
|-----------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------|
| **pathRoots.length == 0** | no computation result registered yet. initial state after request. | computation market could not deliver any solution to given task.      |
| **pathRoots.length == 1** | first result registered. open for challenges.                      | exactly 1 result found. result can be used.                           |
| **pathRoots.length > 1**  | some existing result challenged. cDance in progress.               | more than one result survived the cDance, computation market failed.  |



## about `getStatus()`:

|                       | challengeEndTime > now                                             | challengeEndTime <= now                                               |   |   |
|-----------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------|---|---|
| pathRoots.length == 0 | no computation result registered yet. initial state after request. | computation market could not deliver any solution to given task.      |   |   |
| pathRoots.length == 1 | first result registered. open for challenges.                      | exactly 1 result found. result can be used.                           |   |   |
| pathRoots.length > 1  | some existing result challenged. cDance in progress.               | more than one result survived the cDance, computation market failed.  |   |   |
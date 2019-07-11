// from https://github.com/JesseBusman/EtherPrime/blob/master/EtherPrime.sol
contract PrimeTester {
  
  enum Booly {
    DEFINITELY_NOT,
    PROBABLY_NOT,
    UNKNOWN,
    PROBABLY,
    DEFINITELY
  }
  
  Booly public constant DEFINITELY_NOT = Booly.DEFINITELY_NOT;
  Booly public constant PROBABLY_NOT = Booly.PROBABLY_NOT;
  Booly public constant UNKNOWN = Booly.UNKNOWN;
  Booly public constant PROBABLY = Booly.PROBABLY;
  Booly public constant DEFINITELY = Booly.DEFINITELY;
  
  
  function isPowerOf2(uint256 _number) private pure returns (bool) {
    if (_number == 0) return false;
    else return ((_number-1) & _number) == 0;
  }
  
 // TRY_POW_MOD function defines 0^0 % n = 1
  function TRY_POW_MOD(uint256 _base, uint256 _power, uint256 _modulus) private pure returns (uint256 result, bool success) {
    if (_modulus == 0) return (0, false);
    
    bool mulSuccess;
    _base %= _modulus;
    result = 1;
    while (_power > 0)
    {
      if (_power & uint256(1) != 0)
      {
        (result, mulSuccess) = TRY_MUL(result, _base);
        if (!mulSuccess) return (0, false);
        result %= _modulus;
      }
      (_base, mulSuccess) = TRY_MUL(_base, _base);
      if (!mulSuccess) return (0, false);
      _base = _base % _modulus;
      _power >>= 1;
    }
    success = true;
  }
  
  function TRY_MUL(uint256 _i, uint256 _j) private pure returns (uint256 result, bool success) {
    if (_i == 0) { return (0, true); }
    uint256 ret = _i * _j;
    if (ret / _i == _j) return (ret, true);
    else return (ret, false);
  }
  
  function insecureRand(uint256 _input) private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      _input
    )));
  }
  
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  ////////////                                    ////////////
  ////////////           Miller-rabin             ////////////
  ////////////                                    ////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  
  // This function runs one trial. It returns false if n is
  // definitely composite and true if n is probably prime.
  // d must be an odd number such that d*2^r = n-1 for some r >= 1
  function probabilisticTest(uint256 d, uint256 _number, uint256 _random) private pure returns (bool result, bool success) {
    // Check d
    assert(d & 1 == 1); // d is odd
    assert((_number-1) % d == 0); // n-1 divisible by d
    uint256 nMinusOneOverD = (_number-1) / d;
    assert(isPowerOf2(nMinusOneOverD)); // (n-1)/d is power of 2
    assert(nMinusOneOverD >= 1); // 2^r >= 2 therefore r >= 1
    
    // Make sure we can subtract 4 from _number
    if (_number < 4) return (false, false);
    
    // Pick a random number in [2..n-2]
    uint256 a = 2 + _random % (_number - 4);
    
    // Compute a^d % n
    uint256 x;
    (x, success) = TRY_POW_MOD(a, d, _number);
    if (!success) return (false, false);
    
    if (x == 1 || x == _number-1)
    {
      return (true, true);
    }
    
    // Keep squaring x while one of the following doesn't
    // happen
    // (i)   d does not reach n-1
    // (ii)  (x^2) % n is not 1
    // (iii) (x^2) % n is not n-1
    while (d != _number-1) {
      (x, success) = TRY_MUL(x, x);
      if (!success) return (false, false);
      
      x %= _number;
      
      (d, success) = TRY_MUL(d, 2);
      if (!success) return (false, false);
      
      
      if (x == 1) return (false, true);
      if (x == _number-1) return (true, true);
    }
 
    // Return composite
    return (false, true);
  }
  // This functions runs multiple miller-rabin trials.
  // It returns false if _number is definitely composite and
  // true if _number is probably prime.
  function isPrime_probabilistic(uint256 _number, uint256 _rand) public view returns (Booly) {
    // 40 iterations is heuristically enough for extremely high certainty
    uint256 probabilistic_iterations = 40;
    
    // Corner cases
    if (_number == 0 || _number == 1 || _number == 4)  return DEFINITELY_NOT;
    if (_number == 2 || _number == 3) return DEFINITELY;
    
    // Find d such that _number == 2^d * r + 1 for some r >= 1
    uint256 d = _number - 1;
    while ((d & 1) == 0)
    {
      d >>= 1;
    }
    
    uint256 random = insecureRand(_rand);
    
    // Run the probabilistic test many times with different randomness
    for (uint256 i = 0; i < probabilistic_iterations; i++)
    {
      bool result;
      bool success;
      (result, success) = probabilisticTest(d, _number, random);
      if (success == false)
      {
        return UNKNOWN;
      }
      if (result == false)
      {
        return DEFINITELY_NOT;
      }
      
      // Shuffle bits
      random *= 22777;
      random ^= (random >> 7);
      random *= 71879;
      random ^= (random >> 11);
    }
    
    return PROBABLY;
  }
}
// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0 <0.9.0;


contract WCPOOL {
   struct WcPool{
        string home;
        string visit;
        string rounds;
        uint256 wPool;
        uint256 dPool;
        uint256 lPool;
        uint256 sPool;
        bool decided;
        bool used;
    }
    struct PickingKey{
        address joiner;
        uint256 poolKind; 
        ScoreInfo scoreInfo;
    }
    struct ScoreInfo{
        uint256 homeScore;
        uint256 visitScore;
    }
    address owner;
    mapping (string => uint256) scorePools;
    mapping (string => uint256) joinerInfo;
    mapping (bytes32 => WcPool) WcPools;
    event Transfer(address owner,address spender,uint256 value);
    event Approval(address owner,address spender,uint256 value);
     /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        address holder)  public{
        // Set the symbol for display purposes
        owner = holder;
    }
    function set_Pool(
    string memory home,
    string memory visit,
    string memory rounds,
    bool decided
    ) external  returns (bytes32) {
       string memory s1 = strConcat(home,visit);
       string memory s2 = strConcat(s1,rounds);
       bytes32 poolKey = keccak256(abi.encodePacked(s2));
       if(contains(poolKey)) { 
            revert("pair exist");
       }else{
           WcPools[poolKey].used = true;
           WcPools[poolKey].home = home;
           WcPools[poolKey].visit = visit;
           WcPools[poolKey].rounds = rounds;
           WcPools[poolKey].wPool = 0;
           WcPools[poolKey].dPool = 0;
           WcPools[poolKey].lPool = 0;
           WcPools[poolKey].sPool = 0;
           WcPools[poolKey].decided = decided;

       }
       return poolKey;
    }
    function picking(address joiner,uint256 weight,bytes32 poolKey,uint256 homeScore,uint256 visitScore,uint256 kind) external returns(bool){
        if(!contains(poolKey)) { 
            revert("pool not exist");
       }else{
           WcPool memory pool = WcPools[poolKey];
           string  memory si = strConcat(uint256ToString(homeScore),uint256ToString(visitScore));
           string  memory jk = strConcat(addressToString(joiner),uint256ToString(kind));
           string  memory pk = strConcat(jk,si);
            if (kind == 2){
              pool.sPool += weight;
            }
            else if(kind == 3){
                pool.wPool += weight;
            }else if (kind == 1){
                pool.dPool += weight;
            }else {
                pool.lPool += weight;
            }
           joinerInfo[pk] += weight;
           
       }
    }
    function getPair(bytes32 poolKey) external view returns (string memory home,string memory visit,string memory rounds,uint256 wPool,uint256 dPool,uint256 lPool,uint256 sPool){
        if(!contains(poolKey)) { 
            revert("not exist");
        }else{
            return (WcPools[poolKey].home,
            WcPools[poolKey].visit,
            WcPools[poolKey].rounds,
            WcPools[poolKey].wPool,
            WcPools[poolKey].dPool,
            WcPools[poolKey].lPool,
            WcPools[poolKey].sPool);
        }
    }
    function contains(bytes32 poolKey) internal view returns (bool) {
            return WcPools[poolKey].used;
    }
    function strConcat(string memory _a,string memory _b) internal pure returns (string memory){
            bytes memory _ba = bytes(_a);
            bytes memory _bb = bytes(_b);
            string memory ret = new string(_ba.length + _bb.length);
            bytes memory bret = bytes(ret);
            uint k = 0;
            for(uint i = 0;i < _ba.length;i++) bret[k++] = _ba[i];
            for(uint i = 0;i < _bb.length;i++) bret[k++] = _bb[i];
            return string(ret);
        }
    function addressToString(address a) internal pure returns(string memory){
            return toString(abi.encodePacked(a));
    }
    function uint256ToString(uint256 u) internal pure returns(string memory){
            return toString(abi.encodePacked(u));
    }
    function bytes32ToString(bytes32 b) internal pure returns(string memory){
            return toString(abi.encodePacked(b));
     }
    function toString(bytes memory data) internal pure returns(string memory){
            bytes memory alphabet = "0123456789abcdef";
            bytes memory str = new bytes(2 + data.length * 2);
            str[0] = "0";
            str[1] = "x";
            for(uint i =0;i < data.length;i++){
                str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
                str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
            }
            return string(str);
    }
    function stringCompare(string memory a, string memory b) internal returns(bool){
        if (bytes(a).length != bytes(b).length){
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }
}
   

// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.8.0 <0.9.0;

import "./safemath.sol";
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
        bool finished;
    }
    struct AllScorePool{
        JoinerPicking[] separateBet;
        bytes32  poolKey;
    }
    struct JoinerAllPicking{
        JoinerPicking[] separateBet;
        address  joiner;
    }
    struct JoinerPicking{
        uint256 weight;
        uint256 kind;
        uint256 homeScore;
        uint256 visitScore;
        address  joiner;
        string  pickingKey;
        bool finished;
    }
    using SafeMath for uint256;
    address owner;
    mapping (string => uint256) scorePools;
    //mapping (bytes32 => JoinerPicking) allJoinerInfo;
    mapping (bytes32 => AllScorePool) allScorePoolInfo;
    mapping (string => uint256) singleScorePool;
    mapping (address => JoinerAllPicking) joinerAllPicking;
    mapping (address => uint256) voteAmount;
    mapping (bytes32 => WcPool) WcPools;
    // uint256 nextWDLPoolAmount;
    // uint256 nextScorePoolAmount;
    event Transfer(address owner,address spender,uint256 value);
    event Approval(address owner,address spender,uint256 value);
    event Received(address, uint);
     /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        address holder)  public{
        // Set the symbol for display purposes
        owner = holder;
        // nextWDLPoolAmount = 0;
        // nextScorePoolAmount = 0;
    }
    function Set_Pool(
    string memory home,
    string memory visit,
    string memory rounds,
    bool decided
    ) external onlyManager returns (bytes32) {
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
           WcPools[poolKey].finished = false;

       }
       return poolKey;
    }
    function Picking(address joiner,uint256 weight,bytes32 poolKey,uint256 homeScore,uint256 visitScore,uint256 kind) external onlyManager returns(bool){
        if(!contains(poolKey)) { 
            revert("pool not exist");
       }else{
           if(voteAmount[joiner]<weight){
               revert("not enough voteAmount");
           }
           WcPool memory pool = WcPools[poolKey];
           string  memory si = strConcat(uint256ToString(homeScore),uint256ToString(visitScore));
           string  memory pickingKey = strConcat(bytes32ToString(poolKey),si);
           JoinerPicking memory jp = JoinerPicking(weight,kind,homeScore,visitScore,joiner,pickingKey,false);
           allScorePoolInfo[poolKey].poolKey = poolKey;
           allScorePoolInfo[poolKey].separateBet.push(jp); 
           joinerAllPicking[joiner].joiner = joiner;
           allScorePoolInfo[poolKey].separateBet.push(jp); 
            if (kind == 2){
              pool.sPool += weight;
              singleScorePool[pickingKey] += weight;
            }
            else if(kind == 3){
                pool.wPool += weight;
            }else if (kind == 1){
                pool.dPool += weight;
            }else {
                pool.lPool += weight;
            }
            voteAmount[joiner] -= weight;
           
       }
       return true;
    }
    function Set_Basal(bytes32 poolKey) external onlyManager  returns (bool){
        if(!contains(poolKey)) { 
            revert("pool not exist");
        }else{
           WcPool memory pool = WcPools[poolKey];
           uint256 expect = (pool.wPool+pool.lPool+pool.dPool+pool.sPool).mul(10).div(100);
           return true;
        }
    }
    function Withdrawal(address toAddress,bytes32 poolKey) external onlyManager payable returns (bool){
           if(!contains(poolKey)) { 
                revert("pool not exist");
           }else{
                WcPool memory pool = WcPools[poolKey];
                uint256 expect = (pool.wPool+pool.lPool+pool.dPool+pool.sPool).mul(10).div(100);
                if (pool.finished = true){
                    address payable toAddress_address = payable(toAddress);
                    toAddress_address.transfer(expect);
                }else{
                    revert("pool has not finished");
                }               
           }
    }
    function voteWithdrawal(address joiner,uint256 amount) external onlyManager payable returns (bool){
        if(voteAmount[joiner] >= amount && voteAmount[joiner] >= 0){
            address payable toAddress_address = payable(joiner);
            toAddress_address.transfer(voteAmount[joiner]);
        }else{
            revert("not enough voteAmount");
        }
    }
    function CheckExpect(bytes32 poolKey) external onlyManager  returns (uint256){
        if(!contains(poolKey)) { 
            revert("pool not exist");
        }else{
           WcPool memory pool = WcPools[poolKey];
           uint256 expect = (pool.wPool+pool.lPool+pool.dPool+pool.sPool).mul(10).div(100);
           return expect;
        }
    }
    function Award(bytes32 poolKey,uint256 homeScore,uint256 visitScore,uint256 result)  external onlyManager  payable returns(bool){
        if(!contains(poolKey)) { 
            revert("pool not exist");
       }else{
           WcPool memory pool = WcPools[poolKey];
           JoinerPicking[] memory separateBets = allScorePoolInfo[poolKey].separateBet;
           uint256 allRewardAmount = 0;
        //    nextWDLPoolAmount += (pool.wPool+pool.lPool+pool.dPool) * 0.05;
        //    nextScorePoolAmount += pool.sPool * 0.05;
        //    uint256 wdls =pool.sPool+pool.wPool+pool.lPool+pool.dPool;
        //    uint256 serviceAmount = wdls.mul(15).div(100);
                for (
                uint j = 0;
                j <= separateBets.length-1;
                j ++
                ){
                  if(separateBets[j].finished = false){
                      if(separateBets[j].kind==2){
                          allRewardAmount = pool.sPool.mul(85).div(100);
                      if (separateBets[j].homeScore==homeScore && separateBets[j].visitScore==visitScore){
                          uint256 singleScorePoolAmount = singleScorePool[separateBets[j].pickingKey];
                          uint256 rewardAmount = allRewardAmount * separateBets[j].weight /  singleScorePoolAmount;
                          //reward
                        //   address payable joiner_address = payable(separateBets[j].joiner);
                        //   joiner_address.transfer(rewardAmount);
                        //   separateBets[j].finished = true;
                          //return voteAmount
                          voteAmount[separateBets[j].joiner] += rewardAmount;
                          separateBets[j].finished = true;

                          
                      }
                    }else{
                      if(separateBets[j].kind==result){
                          allRewardAmount = (pool.wPool+pool.lPool+pool.dPool).mul(85).div(100);
                          uint256 pickPoolAmount = 0;
                          if (separateBets[j].kind == 0){
                              pickPoolAmount = pool.lPool.mul(85).div(100);
                          }
                          if (separateBets[j].kind == 1){
                              pickPoolAmount = pool.dPool.mul(85).div(100);
                          }
                          if (separateBets[j].kind == 3){
                              pickPoolAmount = pool.wPool.mul(85).div(100);
                          }
                          uint256 rewardAmount = allRewardAmount * separateBets[j].weight /  pickPoolAmount;
                          //reward
                        //   address payable joiner_address = payable(separateBets[j].joiner);
                        //   joiner_address.transfer(rewardAmount);
                        //   separateBets[j].finished = true;
                          //return voteAmount
                          voteAmount[separateBets[j].joiner] += rewardAmount;
                          separateBets[j].finished = true;
                      }
                    }
                  }  
                }
                pool.finished = true;
                // address payable owner_address = payable(owner);
                // owner_address.transfer(serviceAmount);
       }
       return true;
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
    // @notice 修改器
    modifier onlyManager() { 
        require(
            msg.sender == owner,
            "Only owner can call this."
        );
        _;
    }
    receive() external payable {
         if(msg.sender != owner){
           voteAmount[msg.sender] += msg.value;
           emit Received(msg.sender, msg.value);
         }else{

         }
   }
}
   
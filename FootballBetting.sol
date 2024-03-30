// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FootballBetting {
    address public owner;

    struct Match {
        uint256 id;
        string homeTeam;
        string awayTeam;
        bool finished;
        string winner;
        mapping(address => uint256) bets;
        address[] bettors;
        mapping(address => string) selectedTeams;

    }

    struct MatchInfo {
        uint256 id;
        string homeTeam;
        string awayTeam;
        bool finished;
        string winner;
    }

    Match[] public matches;
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function addMatch(string memory _homeTeam, string memory _awayTeam) public onlyOwner {
        Match storage newMatch = matches.push();
        newMatch.id = matches.length - 1;
        newMatch.homeTeam = _homeTeam;
        newMatch.awayTeam = _awayTeam;
    }

    function finishMatch(uint256 _matchId, string memory _winner) public {
        Match storage matchToFinish = matches[_matchId];
        require(!matchToFinish.finished, "Match has already been finished");
        matchToFinish.finished = true;
        matchToFinish.winner = _winner;
        distributeFunds(_matchId, _winner);
    }

    function getMatchCount() public view returns (uint256) {
        return matches.length;
    }

    function getMatch(uint256 index) public view returns (MatchInfo memory) {
        require(index < matches.length, "Invalid match index");
        Match storage matchData = matches[index];
        return MatchInfo(matchData.id, matchData.homeTeam, matchData.awayTeam, matchData.finished, matchData.winner);
    }

    function placeBet(uint256 _matchId, string memory _selectedTeam) public payable {
        Match storage matchToBet = matches[_matchId];
        require(!matchToBet.finished, "Match has already been finished");
        require(bytes(matchToBet.winner).length == 0, "Match winner has already been determined");
        require(msg.value > 0, "Bet amount must be greater than zero");

        matchToBet.bets[msg.sender] += msg.value;
        matchToBet.bettors.push(msg.sender);
        matchToBet.selectedTeams[msg.sender] = _selectedTeam;
    }

    function distributeFunds(uint256 _matchId, string memory _winner) public payable{
        Match storage finishedMatch = matches[_matchId];
        uint256 totalBets = 0;
        uint256 winnerBets = 0;

        // Calculate total bets and winner bets
        for (uint256 i = 0; i < finishedMatch.bettors.length; i++) {
            address bettor = finishedMatch.bettors[i];
            totalBets += finishedMatch.bets[bettor];
            if (keccak256(bytes(finishedMatch.winner)) == keccak256(bytes(_winner))) {
                winnerBets += finishedMatch.bets[bettor];
            }
        }

        // Distribute funds to winners
        for (uint256 i = 0; i < finishedMatch.bettors.length; i++) {
            address bettor = finishedMatch.bettors[i];
            uint256 betAmount = finishedMatch.bets[bettor];
        if (keccak256(bytes(finishedMatch.selectedTeams[bettor])) == keccak256(bytes(_winner))) {
                    uint256 winnings = (betAmount * totalBets) / winnerBets;
                payable(bettor).transfer(winnings);
                
            }
        }
    }

    
    function getTotalBets(uint256 _matchId) public view returns (uint256) { 
        Match storage _Match = matches[_matchId];
        uint256 totalBets = 0;

        for (uint256 i = 0; i < _Match.bettors.length; i++) {
            address bettor = _Match.bettors[i];
            totalBets += _Match.bets[bettor];
        }

        return totalBets;
    }

}

//
//  Game.swift
//  DiceOff
//
//  Created by Vu Nguyen on 12/27/21.
//

import Foundation
import SwiftUI

class Game: ObservableObject {
    var rows: [[Dice]]
    var changeList = [Dice]()
    
    
    private let numRows: Int
    private let numCols: Int
    private var aiClosedList = [Dice]()
    
    @Published var activePlayer = Player.green
    @Published var state = GameState.waiting
    
    @Published var greenScore = 0
    @Published var redScore = 0
    
    init(rows: Int, colums: Int) {
        numRows = rows
        numCols = colums
        
        self.rows = [[Dice]]()
        
        for rowCount in 0..<numRows {
            var newRow = [Dice]()
            
            for colCount in 0..<numCols {
                let dice = Dice(row: rowCount, col: colCount, neighbors: countNeighbors(row: rowCount, col: colCount))
                newRow.append(dice)
            }
            
            self.rows.append(newRow)
        }
    }
    
    private func countNeighbors(row: Int, col: Int) -> Int {
        var result = 0
        
        if col > 0 { // one to the left
            result += 1
        }
        
        if col < numCols - 1 { // one to the right
            result += 1
        }
        
        if row > 0 { // one above
            result += 1
        }
        
        if row < numRows - 1 { // one below
            result += 1
        }
        
        return result
    }
    
    private func getNeighbors(row: Int, col: Int) -> [Dice] {
        var result = [Dice]()
        
        if col > 0 { // one to the left
            result.append(rows[row][col-1])
        }
        
        if col < numCols - 1 { // one to the right
            result.append(rows[row][col + 1])
        }
        
        if row > 0 { // one above
            result.append(rows[row - 1][col])
        }
        
        if row < numRows - 1 { // one below
            result.append(rows[row + 1][col])
        }
        
        return result
    }
    
    private func bump(_ dice: Dice) {
        dice.value += 1
        dice.owner = activePlayer
        dice.changeAmount = 1
        
        withAnimation {
            dice.changeAmount = 0
        }
        
        if dice.value > dice.neighbors {
            dice.value = 1
            
            for neighbor in getNeighbors(row: dice.row, col: dice.col) {
                changeList.append(neighbor)
            }
        }
    }
    
    private func runChanges() {
        if changeList.isEmpty {
            nextTurn()
            return
        }
        
        let toChange = changeList
        changeList.removeAll()
        
        for dice in toChange {
            bump(dice)
        }
        
        greenScore = score(for: .green)
        redScore = score(for: .red)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.runChanges()
        }
    }
    /*
    private func nextTurn() {
        if activePlayer == .green {
            activePlayer = .red
        } else {
            activePlayer = .green
        }
        
        state = .waiting
    }
    */
    
    private func nextTurn() {
        if activePlayer == .green {
            activePlayer = .red
            state = .thinking
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.executeAITurn()
            }
        } else {
            activePlayer = .green
            state = .waiting
        }
    }
    
    func increment(_ dice: Dice) {
        guard state == .waiting else { return }
        guard dice.owner == .none || dice.owner == activePlayer else { return }
        
        state = .changing
        changeList.append(dice)
        runChanges()
    }
    
    private func score(for player: Player) -> Int {
        var count = 0
        
        for row in rows {
            for col in row {
                if col.owner == player {
                    count += 1
                }
            }
        }
        return count
    }
    
    private func checkMove(for dice: Dice) {
        if aiClosedList.contains(dice) { return }
        aiClosedList.append(dice)
        
        if dice.value + 1 > dice.neighbors {
            // this dice would break if we bump it
            for neighbor in getNeighbors(row: dice.row, col: dice.col) {
                checkMove(for: neighbor)
            }
        }
    }
    
    private func getBestMove() -> Dice? {
        let aiPlayer = Player.red
        var bestDice = [Dice]()
        var bestScore = -9999
        
        for row in rows {
            for dice in row {
                if dice.owner != .none && dice.owner != aiPlayer {
                    // we can't move their pieces
                    continue
                }
                
                aiClosedList.removeAll()
                checkMove(for: dice)
                
                // Is this a good move?
                var score = 0
                
                for checkDice in aiClosedList {
                    if checkDice.owner == .none || checkDice.owner == aiPlayer {
                        score += 1
                    } else {
                        score += 10
                    }
                }
                
                let compareList = getNeighbors(row: dice.row, col: dice.col)
                
                for checkDice in compareList {
                    if checkDice.owner == aiPlayer { continue }
                    
                    if checkDice.value > dice.value {
                        score -= 50
                    } else {
                        if checkDice.owner != .none {
                            // if we bump this dice, it's next to an opponent's piece of lower value, ...
                            score += 10
                        }
                    }
                }
                
                if score > bestScore {
                    // this is a better score than what we had before -- clear all the options ...
                    bestScore = score
                    bestDice.removeAll()
                    bestDice.append(dice)
                } else if score == bestScore {
                    // this move is as good as our previous move
                    bestDice.append(dice)
                }
            }
        }
        
        if bestDice.isEmpty {
            return nil
        }
        
        if Bool.random() {
            // 50% of the time we fortify
            var highestValue = 0
            var selection = [Dice]()
            
            for dice in bestDice {
                if dice.value > highestValue {
                    highestValue = dice.value
                    selection.removeAll()
                    selection.append(dice)
                } else if dice.value == highestValue {
                    selection.append(dice)
                }
            }
            
            return selection.randomElement()
        } else {
            // 50% of the time we play randomly
            return bestDice.randomElement()
        }
    }
    
    private func executeAITurn() {
        if let dice = getBestMove() {
            changeList.append(dice)
            state = .changing
            runChanges()
        } else {
            print("No moves!")
        }
    }
}

module Tests.Internals.TestConstraints where


import Test.HUnit
import System.Random.Mersenne.Pure64 (pureMT)


import Moo.GeneticAlgorithm.Types
import Moo.GeneticAlgorithm.Selection
import Moo.GeneticAlgorithm.Random
import Moo.GeneticAlgorithm.Constraints



testConstraints =
    TestList
    [ "constraint satisfaction" ~: do
        let gs =  [[-1],[0],[1],[2],[3::Int]]
        assertEqual ".<." [True, True, False, False, False] $
                    map (isFeasible [head .<. 1]) gs
        assertEqual ".<=." [True, True, True, False, False] $
                    map (isFeasible [head .<=. 1]) gs
        assertEqual ".>." [False, False, False, True, True] $
                    map (isFeasible [head .>. 1]) gs
        assertEqual ".>=." [False, False, True, True, True] $
                    map (isFeasible [head .>=. 1]) gs
        assertEqual ".==." [False, False, True, False, False] $
                    map (isFeasible [head .==. 1]) gs
        assertEqual "non-strict double inequality" [False, True, True, True, False] $
                    map (isFeasible [(0 .<=..<=. 2) head]) gs
        assertEqual "strict double inequality" [False, False, True, False, False] $
                    map (isFeasible [(0 .<..<. 2) head]) gs
    , "constrained initialization" ~: do
        let constraints = [ (!!0) .>=. 0
                          , ((-1) .<=..<=. 1) (!!1)
                          , (\([x,y]) -> x+y) .<. 5 ]
        let n = 200
        let genomes = flip evalRandom (pureMT 1) $
                      getConstrainedGenomesRs constraints n (replicate 2 (-10,10::Int))
        assertEqual "exactly n genomes" n $
                    length genomes
        assertEqual "first constraint (>=)" True $
                    all (\([x,_]) -> x >= 0) genomes
        assertEqual "second constraint (<= .. <=)" True $
                    all (\([_,y]) -> (-1) <= y && y <= 1) genomes
        assertEqual "third constraint (<)" True $
                    all (\([x,y]) -> (x+y) < 5) genomes
    , "constrained selection (minimizing)" ~: do
        let n = 10
        let tournament2 = tournamentSelect Minimizing 2 n
        let constraints = [head .>=. 0, head .>=. (-1)]
        let ctournament = withConstraints constraints numberOfViolations Minimizing $
                          tournament2
        -- out of two solutions, one violates both constraints, another one only one
        let badvsugly = map (\x -> ([x], x)) [-1, -2]
        -- out of two solutions, one is feasible, the other is not
        let goodvsbad = map (\x -> ([x], x)) [0, -1]
        let result = flip evalRandom (pureMT 1) $ ctournament badvsugly
        assertEqual "lesser degree of violation is preferred"
                    (replicate n (-1.0)) $ (map (head . takeGenome) result)
        let result = flip evalRandom (pureMT 1) $ ctournament goodvsbad
        assertEqual "feasible solution is preferred"
                    (replicate n (0.0)) $ (map (head . takeGenome) result)
    , "numberOfViolations" ~: do
        let constraints = [head .>=. 0, head .>=. (-1)]
        assertEqual "1 violation" 1 $
                    numberOfViolations constraints [-1]
        assertEqual "2 violations" [2, 2] $
                    map (numberOfViolations constraints) [ [-2], [-3] ]
        assertEqual "no violations" 0 $
                    numberOfViolations constraints [0]
    , "degreeOfViolation" ~: do
        let constraints = [head .>=. 0, (negate . head) .<. (1)]
        assertEqual "no violation" 0 $
                    degreeOfViolation 2.0 0.5 constraints [0]
        assertEqual "1 non-strict violation" 0.25 $
                    degreeOfViolation 2.0 0.5 constraints [-0.5]
        assertEqual "1 non-strict and 1 strict violations" 1.5 $
                    degreeOfViolation 2.0 0.5 constraints [-1.0]
    ]
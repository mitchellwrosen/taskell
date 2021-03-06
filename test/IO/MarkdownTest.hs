{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module IO.MarkdownTest (
    test_markdown
) where

import ClassyPrelude

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.ExpectedFailure (ignoreTest)

import IO.Markdown.Internal (start, parse, listStringify)
import IO.Config (MarkdownConfig(..), defaultMarkdownConfig, defaultConfig)
import Data.Taskell.Lists (Lists, newList, appendToLast)
import Data.Taskell.Task (Task, new, subTask, addSubTask)

-- alternative markdown configs
alternativeMarkdownConfig :: MarkdownConfig
alternativeMarkdownConfig = MarkdownConfig {
    titleOutput = "##",
    taskOutput = "###",
    subtaskOutput = "-"
}

-- useful records
task :: Task
task = new "Test Item"

list :: Lists
list = newList "Test" empty

listWithItem :: Lists
listWithItem = appendToLast task list

makeSubTask :: Bool -> Lists
makeSubTask b = appendToLast (addSubTask (subTask "Blah" b) task) list

-- tests
test_markdown :: TestTree
test_markdown =
    testGroup "IO.Markdown" [
        testGroup "Line Parsing" [
            testGroup "Default Format" [
                testCase "List Title" (
                    assertEqual
                        "One list"
                        (list, [])
                        (start defaultMarkdownConfig (empty, []) ("## Test", 1))
                )

              , testCase "Blank line" (
                    assertEqual
                        "Nothing"
                        (empty, [])
                        (start defaultMarkdownConfig (empty, []) ("", 1))
                )

              , testCase "Just spaces" (
                    assertEqual
                        "Nothing"
                        (empty, [])
                        (start defaultMarkdownConfig (empty, []) ("        ", 1))
                )

              , testCase "Error" (
                    assertEqual
                        "Error on line 1"
                        (empty, [1])
                        (start defaultMarkdownConfig (empty, []) ("Test", 1))
                )

              , testCase "List item" (
                    assertEqual
                        "List item"
                        (listWithItem, [])
                        (start defaultMarkdownConfig (list, []) ("- Test Item", 1))
                )

              , testCase "Sub-Task" (
                    assertEqual
                        "List item with Sub-Task"
                        (makeSubTask False, [])
                        (
                            start
                                defaultMarkdownConfig
                                (listWithItem, [])
                                ("    * Blah", 1)
                        )
                )

              , testCase "Complete Sub-Task" (
                    assertEqual
                        "List item with Sub-Task"
                        (makeSubTask True, [])
                        (start defaultMarkdownConfig (listWithItem, []) ("    * ~Blah~", 1))
                )

              , ignoreTest $ testCase "List item without list" (
                    assertEqual
                        "Parse Error"
                        (empty, [1])
                        (start defaultMarkdownConfig (empty, []) ("- Test Item", 1))
                )

              , ignoreTest $ testCase "Sub task without list item" (
                    assertEqual
                        "Parse Error"
                        (list, [1])
                        (start defaultMarkdownConfig (list, []) ("    * Blah", 1))
                )
            ]

          , testGroup "Alternative Format" [
                testCase "List Title" (
                    assertEqual
                        "One list"
                        (list, [])
                        (start alternativeMarkdownConfig (empty, []) ("## Test", 1))
                )

              , testCase "Blank line" (
                    assertEqual
                        "Nothing"
                        (empty, [])
                        (start alternativeMarkdownConfig (empty, []) ("", 1))
                )

              , testCase "Just spaces" (
                    assertEqual
                        "Nothing"
                        (empty, [])
                        (start alternativeMarkdownConfig (empty, []) ("        ", 1))
                )

              , testCase "Error" (
                    assertEqual
                        "Error on line 1"
                        (empty, [1])
                        (start alternativeMarkdownConfig (empty, []) ("* Test", 1))
                )

              , testCase "List item" (
                    assertEqual
                        "List item"
                        (listWithItem, [])
                        (start alternativeMarkdownConfig (list, []) ("### Test Item", 1))
                )

              , testCase "Sub-Task" (
                    assertEqual
                        "List item with Sub-Task"
                        (makeSubTask False, [])
                        (start alternativeMarkdownConfig (listWithItem, []) ("- Blah", 1))
                )

              , testCase "Complete Sub-Task" (
                    assertEqual
                        "List item with Sub-Task"
                        (makeSubTask True, [])
                        (start alternativeMarkdownConfig (listWithItem, []) ("- ~Blah~", 1))
                )
            ]
        ]

      , testGroup "Parsing" [
            testCase "List Title" (
                assertEqual
                    "One empty list"
                    (Right list)
                    (parse defaultConfig (encodeUtf8 "## Test"))
            )

          , testCase "List Items" (
                assertEqual
                    "List with item"
                    (Right listWithItem)
                    (parse defaultConfig (encodeUtf8 "## Test\n- Test Item"))
            )

          , testCase "Parsing Errors" (
                assertEqual
                    "Errors"
                    (Left "could not parse line(s) 3, 5")
                    (parse defaultConfig (encodeUtf8 "## Test\n- Test Item\n* Spoon\n- Test Item\nCow"))
            )
        ]

      , testGroup "Stringification" [
            testGroup "Default Format" [
                testCase "Standard list" (
                    assertEqual
                        "Markdown formatted output"
                        "## Test\n\n- Test Item\n"
                        (foldl' (listStringify defaultMarkdownConfig) "" listWithItem)
                )

              , testCase "Standard list with sub-task" (
                    assertEqual
                        "Markdown formatted output"
                        "## Test\n\n- Test Item\n    * ~Blah~\n"
                        (foldl' (listStringify defaultMarkdownConfig) "" (makeSubTask True))
                )
            ],

            testGroup "Alternative Format" [
                testCase "Standard list" (
                    assertEqual
                        "Markdown formatted output"
                        "## Test\n\n### Test Item\n"
                        (foldl' (listStringify alternativeMarkdownConfig) "" listWithItem)
                )

              , testCase "Standard list with sub-task" (
                    assertEqual
                        "Markdown formatted output"
                        "## Test\n\n- Test Item\n    * Blah\n"
                        (foldl' (listStringify defaultMarkdownConfig) "" (makeSubTask False))
                )
            ]
        ]
    ]

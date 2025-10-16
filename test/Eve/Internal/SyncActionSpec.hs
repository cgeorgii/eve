module Eve.Internal.SyncActionSpec where

import Test.Hspec
import Control.Concurrent
import Control.Concurrent.MVar
import Control.Monad.IO.Class (liftIO)
import Fixtures
import Control.Lens
import Eve

-- Event type for querying names
data GetNames = GetNames

-- Listeners that provide names (monoidal results)
nameProvider1 :: GetNames -> App [String]
nameProvider1 GetNames = return ["Alice", "Bob"]

nameProvider2 :: GetNames -> App [String]
nameProvider2 GetNames = return ["Charlie", "Diana"]

-- Test that syncActionProvider returns results from dispatchEvent
syncActionWithResultTest :: App ()
syncActionWithResultTest = do
  -- Set up listeners that return monoidal results
  addListener_ nameProvider1
  addListener_ nameProvider2

  -- Set up sync provider that dispatches action and gets result back
  syncActionProvider $ \dispatch -> do
    -- Wait a bit to ensure event loop has started
    threadDelay 100000
    -- This runs in a forked thread, dispatch runs action in event loop
    names <- dispatch (dispatchEvent GetNames :: App [String])
    -- Use dispatchActionAsync to update state with result
    dispatch (store .= show (names :: [String]) >> exit)

spec :: Spec
spec = do
  describe "syncActionProvider" $ do
    describe "with monoidal result building" $ do
      syncState <- ioTest syncActionWithResultTest
      it "Returns monoidal results from dispatchEvent" $
        (syncState ^. store) `shouldBe` show ["Charlie", "Diana", "Alice", "Bob"]

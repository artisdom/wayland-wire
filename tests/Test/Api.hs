{-# LANGUAGE TemplateHaskell #-}
module Test.Api
    ( apiTests )
where

import Control.Applicative
import Control.Concurrent
import Control.Monad.IO.Class
import Data.Word
import Graphics.Wayland.Dispatch
import Graphics.Wayland.Types
import Graphics.Wayland.W
import Test.Arbitrary ()
import Test.Api.Gen
import qualified Test.Api.Client as C
import qualified Test.Api.Server as S
import Test.QuickCheck
import Test.QuickCheck.Monadic

$(genTests 'quickCheckResult)

generatedTests :: IO Bool
generatedTests = and . map checkResult <$> mapM execTest allTests

execTest :: (String, IO Result) -> IO Result
execTest (name, test) = putStrLn ("=== " ++ name ++ " ===") *> test <* putStrLn ""

checkResult :: Result -> Bool
checkResult (Success {}) = True
checkResult _            = False

-- | Checks that a new object is created when calling a request taking a new_id.
prop_newReq :: Word32 -> Property
prop_newReq w = monadicIO $ do
    (s, (c, w')) <- runTest server client
    stop $ s === c .&&. w === w'
    where
        server = do
            let obj = Object 1
            mvar <- liftIO newEmptyMVar
            registerObject
                obj
                ( S.OneArgumentSlots
                { S.oneArgumentReqNewId = \cons -> cons (\_ -> return undefined) >>= liftIO . putMVar  mvar }
                )

            recvAndDispatch

            new <- liftIO $ readMVar mvar
            S.oneArgumentEvtUint (signals new) w
            return (unObject new)

        client = do
            obj  <- objectFromNewId <$> allocObject
            mvar <- liftIO newEmptyMVar
            new  <- C.oneArgumentReqNewId
                (signals obj)
                (\_ -> return $ C.OneArgumentSlots { C.oneArgumentEvtUint = liftIO . putMVar mvar } )

            recvAndDispatch
            w' <- liftIO $ readMVar mvar

            return (unObject new, w')

return []
apiTests :: IO Bool
apiTests =
    (&&)
    <$> $quickCheckAll
    <*> generatedTests

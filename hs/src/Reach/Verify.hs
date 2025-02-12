module Reach.Verify (verify) where

import Control.Monad
import qualified Data.Text as T
import Reach.AST.LL
import Reach.Connector
import Reach.Counter
import Reach.Verify.Knowledge
import Reach.Verify.SMT
import Reach.Verify.Shared
import System.Exit

data VerifierName = Boolector | CVC4 | Yices | Z3
  deriving (Read, Show, Eq)

verify :: Maybe (T.Text -> String) -> Maybe [Connector] -> LLProg -> IO ExitCode
verify outnMay mvcs lp@(LLProg _ llo _ _ _ _ _) = do
  vst_res_succ <- newCounter 0
  vst_res_fail <- newCounter 0
  let vst = VerifySt {..}
  verify_knowledge (($ "know") <$> outnMay) vst lp
  --- The verifier should not be choosable by the user, but we may
  --- automatically select different provers based on the attributes
  --- of the program.
  let smt :: String -> [String] -> IO ()
      smt s a = void $ verify_smt (($ "smt") <$> outnMay) mvcs vst lp s a
  case Z3 of
    Z3 ->
      smt "z3" ["-smt2", "-in"]
  -- XXX "pattern match is redundant"
  -- Yices ->
  --   -- known not to work.
  --   -- - doesn't support declare-datatypes
  --   smt "yices-smt2" []
  -- CVC4 ->
  --   smt "cvc4" ["--lang=smt2", "--incremental"]
  -- Boolector ->
  --   -- known not to work.
  --   -- - doesn't support unsat-cores
  --   -- - doesn't support declare-datatypes
  --   smt "boolector" ["--smt2"]
  ss0 <- readCounter vst_res_succ
  let ss = ss0 + (llo_droppedAsserts llo)
  fs <- readCounter vst_res_fail
  putStr $ "Checked " ++ (show $ ss + fs) ++ " theorems;"
  case fs == 0 of
    True -> do
      putStrLn $ " No failures!"
      return ExitSuccess
    False -> do
      putStrLn $ " " ++ show fs ++ " failures. :'("
      return $ ExitFailure 1

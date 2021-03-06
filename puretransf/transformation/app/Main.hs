{-# LANGUAGE QuasiQuotes #-} 

import Syntax (Expr,AllDclr)
--import Eval (runMain)
import Parser (parseExpr,parseDclr,parseTokens)
import Print (runPrint)
import Transformation ( runTransformation)
import System.ShQQ
import Control.Monad.Trans
import System.Console.Haskeline
import Data.Function
import qualified Data.Map as Map 

process :: String -> IO (String, String)
process input = do
  let tokens = parseTokens input
--  return $ ("Tokens: " ++ show tokens)
 -- let ast = parseExpr input
--  return $("Syntax Expr: " ++ show ast)
  return (p1,p2) 
  where
      mainAst = parseDclr input
      (p1,p2) = 
        case mainAst of
          Left err -> (err, err)
       --     return $ "Parse Error:"
          Right ast ->  ((execPrint ast),(execTransformation ast)) --show ast ++"\n"++ 
 
execPrint :: [AllDclr]-> String
execPrint ast = runPrint ast "\n"--("{--Syntax Dclr: " ++ show ast ++ "--}\n") ++(runPrint ast)++ "\n" 

execTransformation :: [AllDclr]-> (String)
execTransformation ast = runPrint transformed "\n" --("{--"++show (runTransformation ast)) ++"--}\n" ++(runPrint transformed) --
  where transformed = runTransformation ast Map.empty

main :: IO ()
main = runInputT defaultSettings loop
  where
  loop = do
    minput <- getInputLine "Happy> "
    case minput of
      Nothing -> outputStrLn "Goodbye."
      Just ((':'):('l'):(' '):inputFile) -> 
                 liftIO 
                 (((readInput $ inputFile++".hs")>>= process) >>= 
                 (\(str1,str2) -> (writeOutput inputFile str1 str2 ))>>=
                 (\_-> [sh| ghc $file1 |])>>=
                 (\comp1-> [sh| ghc $file2 |]>>= 
                 (\comp2-> [sh| ./$exec1 |]>>= 
                 (\exec1->([sh| ./$exec2 |])>>=
                 (\exec2-> putStrLn (comp1++"Output:\n"++exec1 ++"\n"++comp2++"Transformated Output:\n"++exec2)))))>>=
                 (\_->[sh| rm $out1 $out2 $exec1 $exec2|])) >> loop
                 where
                    file1 = (inputFile ++"Output.hs")
                    file2 = (inputFile ++ "TranfOutput.hs")
                    out1 = (inputFile ++"Output.o")
                    out2 = (inputFile ++ "TranfOutput.o") 
                    exec1 = (inputFile ++"Output")
                    exec2 = (inputFile ++ "TranfOutput")     
        --       ((liftIO  ((readInput inputFile)>>= process)) >>= outputStrLn)>> loop 
      Just input -> (liftIO $ process input) >> loop


writeOutput :: FilePath -> String -> String ->IO()
writeOutput i1 str1 str2 = do 
  writeFile (i1++"Output.hs") (langExtensions++ str1++forMain)
  writeFile (i1++ "TranfOutput.hs") (langExtensions++"import "++ i1 ++ "MConvert \n" ++ imports ++ str2++forTranfMain)
  writeFile (i1++"MConvert.hs") ("module "++ i1 ++ "MConvert" ++mConvert)

readInput:: FilePath ->IO String
readInput fileName = do 
                       contents <- readFile fileName
                       return contents 


mConvert:: String
mConvert = 
  " where \n\n" ++ imports
  ++"mConvert0 :: a -> Eff r a \nmConvert0 =return \n\n"
  ++ "mConvert1 :: (t -> a) -> (t -> Eff r a) \nmConvert1 f x = return(f x) \n\n"
  ++ "mConvert2:: (t2 -> t1 -> a) -> t2 -> Eff r (t1 -> Eff r a) \nmConvert2 f x = return $ mConvert1 $ f x \n\n"
  ++ "mConvert3 :: (t -> t2 -> t1 -> a) -> t -> Eff r (t2 -> Eff r (t1 -> Eff r a)) \nmConvert3 f x =return $ mConvert2 $ f x \n\n"
  ++ binop  


forMain:: String
forMain = 
 "\nmain::IO ()\nmain= putStrLn $show $result"

forTranfMain:: String
forTranfMain = "\nmain::IO ()\nmain= putStrLn $show $run $result"                     

binop:: String 
binop = 
  "\nplus::(Num a)=> Eff r (a->Eff r (a-> Eff r a))\n"++
  "plus = let plus' x y = return (x+y) in return (mConvert1 plus')\n\n"++
  "\nsub::(Num a)=> Eff r (a->Eff r (a-> Eff r a))\n"++
  "sub = let sub' x y = return (x-y) in return (mConvert1 sub')\n\n"++
  "\nmultiple::(Num a)=> Eff r (a->Eff r (a-> Eff r a))\n"++
  "multiple = let multiple' x y = return (x*y) in return (mConvert1 multiple')\n\n"++
  "cons:: Eff r (a-> Eff r ([a]->Eff r [a]))\n"++
  "cons = let cons' x xs = return (x:xs) in return (mConvert1 cons')\n\n"



imports::String
imports =
  "import Control.Eff\nimport Control.Monad\n\n" 


langExtensions:: String
langExtensions = "{-# LANGUAGE ScopedTypeVariables #-}\n\n"  

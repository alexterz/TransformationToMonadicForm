{-# LANGUAGE ScopedTypeVariables #-}
{-#LANGUAGE FlexibleContexts, TypeOperators, DataKinds #-}
{-# LANGUAGE MonoLocalBinds #-}

import Control.Eff
import Control.Eff.Reader.Strict
import Control.Eff.State.Strict
import Control.Eff.Exception
import Control.Eff.Trace
import Control.Monad
import MConvert
import ForTesting
import Data.OpenUnion




testEither ::  (Member (Exc String) r) =>((Eff r (Either String Integer ))-> (Integer-> (Eff r Integer)))
testEither =  (let testEither' x i = ((return x)>>=( \ c0  -> (case c0 of (Left s)->((return s)>>=( \ e2  -> (throwError e2))); )));;in  testEither');      



t12:: (Eff (Exc Integer ': r) Integer)-> Eff r (Either Integer Integer) 
t12 x = runError x

t13:: Eff r (Either Integer Integer) ->Eff r  Integer
t13 x  = 
  x>>= \c0 -> 
  case c0 of
    Left a ->  return a
    Right a -> return a

tryBoth:: ((Member (Exc String) r, Member (State Integer) r)) =>Eff r Integer -> Eff  r Integer -> Eff r Integer;
tryBoth exc st = exc>>= (\x -> (st>>= (\y-> return (x+y))))

exc:: Eff (Exc String ': r) Integer -> Eff r (Either String Integer)
exc x = runError (x) 


alex' :: (Eff r ((Eff r Integer )-> (Eff r Integer )) )
alex' = (return (let alex'' x = (return 1);;in alex''));
sub1 :: (Eff r (Integer-> (Eff r Integer )) )
sub1 = (return (let sub1' x = (((return 1)>>=( \ x2  -> (((return x)>>=( \ x3  -> (sub>>=( \ g3  -> (g3 x3)))))>>=( \ g2  -> (g2 x2)))))>>=( \ x0  -> ((return return)>>=( \ g0  -> (g0 x0)))));;in sub1'));

sub::(Num a)=> Eff r (a->Eff r (a-> Eff r a))
sub = let sub' x y = return (x-y) in return (mConvert1 sub')

one :: Eff r Integer
--one :: (Eff r Integer )
one = (let one' = (((return 1)>>=( \ x1  -> (sub1>>=( \ g1  -> (return(g1 x1))))))>>=( \ x0  -> (alex'>>=( \ g0  -> (g0 x0)))));;in one');


maplet:: (a-> b) -> [a]->  [b]
maplet f [] = []
maplet f (x:xs) =
  let
    h= f x
    t = maplet f xs 
  in
    h:t

mapletK::  (Eff r ( (a->Eff r b) -> Eff r ([a]-> Eff r [b])))
mapletK = 
  let
     mapletK':: (a->Eff r b)-> [a]->Eff r [b]
     mapletK' f [] = return []
     mapletK' f (x:xs) = 
      let
         h = f x
         t = (mapletK >>= (\g-> (g f)))>>=(\g1-> (g1 xs))
      in 
         h>>=(\h1->(t>>=(\t1-> return (h1:t1))))  
  in 
    return(mConvert1 mapletK')   


cons:: Eff r (a-> Eff r ([a]->Eff r [a]))
cons =
  let
     cons' x xs = return (x:xs)
  in 
     return (mConvert1 cons')   

plus:: forall a b r.(Num a ) => Eff r (a->Eff r (a-> Eff r a))
plus = 
  let
     plus x y = return (x+y)
  in
     return (mConvert1 plus)   

mapE:: Eff r (Eff r (a->Eff r b) -> Eff r ([a]-> Eff r [b]))
mapE = 
  let
    -- mapE':: (Eff r (a->Eff r b)) -> ([a]-> Eff r [b])
     mapE f [] = return []
     mapE f (h:t) = f>>= (\f'-> ((f' h) >>= (\h' -> (mapE f t >>= \t' -> return (h':t')))))
  in
    return (mConvert1 mapE)



mapA:: Eff r ((a-> Eff r b) -> Eff r ([a] -> Eff r [b]))
mapA = 
  let
    mapA f [] = return []
    mapA f (h:t) = (f h) >>= (\h' -> (mapA f t >>= \t' -> return (h':t') ))
  in
    return (mConvert1 mapA)  

mapK f [] = []
mapK f (x:xs) = f x : mapK f xs 


--map'':: (a-> Eff r b) -> [a] -> Eff r [b]
map'' f [] = return []
map'' f (h:t) = (f h) >>= (\h' -> (map'' f t >>= \t' -> return (h':t') ))


map':: (a-> Eff r b) -> [a] -> Eff r [b]
map' f [] = return []
map' f (h:t) = do
                 h'<- f h 
                 t'<- map' f t
                 return (h':t')

--mapNew:: (a-> Eff r b) -> Eff r ([a] -> Eff r [b])
mapEff:: (a-> Eff r b) -> Eff r ([a] -> Eff r [b])
mapEff = mConvert1 map''


--examples with map'

t1 = run $ runReader (10::Int) (map'' f [1..5])
     where f x = ask `add` return x
--[11,12,13,14,15]

-- totalAdd imported from ForTesting, i sthe function that giving a x, returns the (x + Env + (s+1)), and increases the state 

t2 = run $ runState (5::Int) $ runReader (10::Int) $ map''  totalAdd [1..5]
--([17,19,21,23,25],10)

--examples with mapNew

--t3 :: ([Int] -> Eff' [Reader Int, State Int] [Int], Int)

t3 = fst $ run $ runState (5::Int) $ runReader (10::Int) $ mapEff  totalAdd 

t4 = run((mapA >>= (\f -> f addOne)) >>= \g -> g [1,2]) 
t3'=  run $ runState (5::Int) $ runReader (10::Int) $ t3 [1..5]
--([17,19,21,23,25],10)

{-- for IO monad
map'':: (Monad m,SetMember Lift (Lift m) r)=> (a-> m b) -> [a] -> Eff r [b]
map'' f [] = return []
map'' f (h:t) = do
                 h'<- lift $ f h 
                 t'<- map'' f t
                 return (h':t')
--}



{--
mapMdebug:: (Show a, Member Trace r) => (a -> Eff r b) -> [ a] -> Eff r [ b]
mapMdebug f [] = return []
mapMdebug f (h:t) = do
                      trace $ "mapMdebug: " ++ show h
                      h' <- f h
                      t' <- mapMdebug f t
                      return (h': t')



tMd = runTrace $ runReader (10:: Int) (mapMdebug f [1..5]) 
      where f x = ask `add` return x

--}

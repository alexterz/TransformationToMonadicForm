
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MonoLocalBinds #-}


import Control.Eff
import Control.Eff.Reader.Strict
import Control.Eff.State.Strict
import Control.Eff.Exception
import Control.Eff.Trace
import Control.Monad
import MConvert
import ForTesting


{--
foldr            :: (a -> b -> b) -> b -> [a] -> b
foldr f z []     =  z
foldr f z (x:xs) =  f x (foldr f z xs)
--}

{--
frec':: Integer-> Eff r Integer 
frec' 0 = return 0
frec' x = (minusEff >>= ( \g -> g x))>>= \x0 -> frec' x0  

--}


foldrK ::Eff r ( (a->Eff r (b -> Eff r b)) -> Eff r (b-> Eff r ([a] -> Eff r b)))
foldrK=
  let 
    foldrK' f z [] = (return z);
    foldrK' f z (x : xs) = (foldrK >>= (\g -> g f >>= (\g1-> g1 z>>= (\g2 -> g2 xs))))>>=
      ( \ x0  -> (f x >>=( \ g0  -> (g0 x0))))
  in
    return (mConvert2 foldrK')
frec::(Integer-> Integer)
frec 0 = 0
frec x = frec (minus x)

frec'::Eff r (Integer-> Eff r Integer)
frec' =
  let
    --frec':: Integer-> Eff r Integer 
    frec' 0 = return 0
    frec' x = (minusEff >>= ( \g -> g x))>>= \x0 -> frec' x0  
  in
    return frec'

minus:: (Integer->Integer)
minus x = x-1

minusEff:: Eff r(Integer -> Eff r Integer)
minusEff = 
    let
       minusEff x = return (x-1)
    in
       return (minusEff)

foldrE:: Eff r (Eff r (a->Eff r (b -> Eff r b)) -> Eff r (b-> Eff r ([a] -> Eff r b)))
foldrE =
 let 
   -- foldrE::(Eff r (a-> Eff r (b -> Eff r b))) -> b -> [a] -> Eff r b
    foldrE f z [] = return z
    foldrE f z (x:xs) = ((((foldrE f) z) xs)>>=( \ x0  -> (((return x)>>=( \ x1  -> (f>>=( \ g1  -> (g1 x1)))))>>=( \ g0  -> (g0 x0)))))
 in
    return (mConvert2 foldrE)           

foldr'' ::(a-> Eff r (b -> Eff r b)) -> b -> [a] -> Eff r b
foldr'' f z [] = (return z);
foldr'' f z (x : xs) = ((((foldr'' f) z) xs)>>=( \ x0  -> (((return x)>>=( \ x1  -> ((return f)>>=( \ g1  -> (g1 x1)))))>>=( \ g0  -> (g0 x0)))));
{--
foldr'' ::Monad m => (a-> m (b -> m b)) -> b -> [a] -> m b
foldr'' f z [] = return z
foldr'' f z (x:xs) = foldr'' f z xs >>= \y -> f x >>= \g -> g y--g y>>= \h -> return h 
--}
--foldr' ::Monad m => (a-> m (b -> m b)) -> b -> [a] -> m b
foldr' ::(a-> Eff r (b -> Eff r b)) -> b -> [a] -> Eff r b
foldr' f z [] = return z
foldr' f z (x:xs) = do
                       y  <- foldr' f z xs
                       g  <- f x 
                       h  <- g y
                       return h

--foldrEff:: (Monad m, Monad m1, Monad m2) => (a-> m (b -> m b)) -> m1 (b -> m2 ([a] -> m b))
foldrEff ::Eff r ((a-> Eff r (b -> Eff r b)) -> Eff r (b -> Eff r ([a] -> Eff r b)))-- or r1=r2=r 
foldrEff =return ( mConvert2 foldr')




-- examples

--addEnvState imported from ForTesting module, uses addEnv to calculate the sum (x+env+s1+1), and increase the state 

--r is the union of r1-r2. It needs type annotation
t1:: (Member (State Int) r, Member (Reader Int) r) => Eff r Int
t1  = (foldr' addEnvState 0 [0,5])  -- addEnvState 0 (addEnvState 0)

--here you can run t1'', without type annotation, because its type is inferred by the run functions that you use
--t1'' = run $ runState (0::Int) $ runReader (1::Int) $ foldr' addEnvState 0 [0,0]

t1' = run $ runState (0::Int) $ runReader (1::Int) $ t1  -- addEnvState 0 (1+1+0) = 2+1+5 +0 (+1+1) 
--(10,2)

-- Every r, is inferred by the run functions that you use.
--here, for example, foldrEff 0 [0,5] has type ::(Member (State Int)r1, Member (State Int) r, Member (Reader Int) r)) =>  Eff r1 (b -> Eff r2 ([a] -> Eff r b)), while r2 = [] (or Void)
--t2 = run $ runState (5::Int) $ runReader (0::Int) $ ( run $ (fst (run $ runState (0::Int) $ (foldrEff addEnvState))) 0) [0,5]
--(18,7)




                            

    

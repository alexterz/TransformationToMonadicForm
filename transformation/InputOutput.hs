{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE AllowAmbiguousTypes #-}

import Control.Monad.State.Strict

foldrK :: ((a-> (b-> b))-> (b-> ([a]-> b)))
foldrK f z [] = z;foldrK f z (x : xs) = ((f x) (((foldrK f) z) xs));
mapK :: ((a-> b)-> ([a]-> [b]))
mapK f [] = [];mapK f (x : xs) = ((f x):((mapK f) xs));
plus1 :: (Integer-> Integer)
plus1 x = (x+1);
plus2 :: (Integer-> (Integer-> Integer))
plus2 x y = (x+y);
alex :: (Integer-> Integer)
alex x = (x-1);
sub1 :: (Integer-> (State Integer Integer ))
sub1 x = (return (x-1));
intermediate :: ([Integer]-> [Integer])
intermediate = (maplet alex);
inter :: ((Integer-> (Integer-> Integer))-> (Integer-> ([Integer]-> Integer)))
inter f = (foldrK f);
alex' :: (Integer-> ((State Integer Integer )-> Integer))
alex' x y = (1+x);
maplet :: forall a b .((a-> b)-> ([a]-> [b]))
maplet f [] = [];maplet f (x : xs) = (let h :: b;h = (f x);t :: [b];t = ((maplet f) xs);z :: Integer;z = (alex 1);in (h:t));
mid :: (Integer,Integer)
mid = ((runState (((example plusMonads) 1) (return 2))) 7);
example ::  (Monad m) =>(((m Integer )-> ((m Integer )-> (m Integer )))-> (Integer-> ((m Integer )-> (m Integer ))))
example f a b = ((plusMonads (return a)) b);
plusMonads ::  (Monad m) =>((m Integer )-> ((m Integer )-> (m Integer )))
plusMonads x y = (x>>=( \ z  -> (y>>=( \ v  -> (return (v+z))))));
addState :: ((State Integer Integer )-> (State Integer Integer ))
addState x = (x>>=f);
f :: (Integer-> (State Integer Integer ))
f p = (get>>=(g p));
g :: (Integer-> (Integer-> (State Integer Integer )))
g a s = (return (a+s));
addState' :: ((State Integer Integer )-> (State Integer Integer ))
addState' x = (x>>=( \ q  -> (get>>=( \ y  -> ((put (y+1))>>=( \ z  -> (return (y+q))))))));
createStMonad :: (Integer-> (Integer,Integer))
createStMonad s = (1,s);
sum1 :: (State Integer Integer )
sum1 = (addState' (return 1));
tryBind :: (Integer-> (Integer-> (State Integer Integer )))
tryBind x y = ((return (x+y))>>=( \ z  -> (return z)));
result :: (Integer,Integer)
result = ((runState (addState' ((tryBind 4) 5))) 2);

main::IO ()
main= putStrLn $show $result
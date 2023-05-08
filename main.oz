functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Application
   Open
   OS
   Property
   Browser
define
   NG = 2
   Dummy % Variable for dev
   TreeDatabase % Variable Globale
   NFiles % Variable globale
   TweetsFolder % Variable globale
   InputText % Pour Press
   OutputText % Pour Press
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Pour ouvrir les fichiers
   class TextFile
      from Open.file Open.text
   end

   %{BrowserObject.option(representation strings:true)}
   proc {Browse Buf}
      {Browser.browse Buf}
   end
   
   %%% /!\ Fonction testee /!\
   %%% @pre : les threads sont "ready"
   %%% @post: Fonction appellee lorsqu on appuie sur le bouton de prediction
   %%%        Affiche la prediction la plus probable du prochain mot selon les deux derniers mots entres
   %%% @return: Retourne une liste contenant la liste du/des mot(s) le(s) plus probable(s) accompagnee de
   %%%          la probabilite/frequence la plus elevee.
   %%%          La valeur de retour doit prendre la forme:
   %%%                  <return_val> := <most_probable_words> '|' <probability/frequence> '|' nil
   %%%                  <most_probable_words> := <atom> '|' <most_probable_words>
   %%%                                           | nil
   %%%                  <probability/frequence> := <int> | <float>
   fun {Press}
      % Lancer le thread assistant
      % thread {PressHelper} end

      % Procédure principale
      local Words WordsTree BestAndTotal Val Freq Ans
         % Renvoie le sub tree des potentiels N+1e mots
         fun {FindSubTree Words Tree}
            case Words of nil then Tree
            else
               case Tree of leaf then nil
               [] tree(key:Y value:V T1 T2) then
                  local Letter TheKey in
                     Letter = {String.toAtom Words.1}
                     TheKey = {String.toAtom Y}

                     if {Int.is V} then Tree
                     elseif Letter == TheKey then {FindSubTree Words.2 V}
                     elseif Letter < TheKey then {FindSubTree Words T1}
                     elseif Letter > TheKey then {FindSubTree Words T2}
                     end
                  end
               end
            end
         end
         % Renvoie Best|Total|nil, avec Total la somme des occurences de tous les mots, et Best le meilleur nombre d'occurences
         fun {FindBestAndTotal SubTree TotLoc BestLoc}
            local LeftResult NewTot NewBest in
               case SubTree of leaf then BestLoc|TotLoc|nil
               [] tree(key:Y value:V T1 T2) then
                  if SubTree.value > BestLoc then LeftResult = {FindBestAndTotal T1 TotLoc SubTree.value}
                  else LeftResult = {FindBestAndTotal T1 TotLoc BestLoc} 
                  end
                  
                  NewTot = TotLoc + LeftResult.2.1 + SubTree.value
                  NewBest = LeftResult.1
                  {FindBestAndTotal T2 NewTot NewBest}
               else 0
               end
            end
         end
         % Sur base du meilleur nom d'occurences, renvoies une liste des mots concernés
         fun {FindWords TheVal SubTree List}
            local LeftResult in
               case SubTree of leaf then List
               [] tree(key:Y value:V T1 T2) then
                  if SubTree.value == TheVal then LeftResult = {FindWords TheVal T1 Y|List}
                  else LeftResult = {FindWords TheVal T1 List}
                  end
                  {FindWords TheVal T2 LeftResult}
               end
            end
         end
         fun {TestLen X}
            local 
               fun {TestLenLoc X Acc}
                  case X of nil then Acc
                  [] H|T then {TestLenLoc X.2 Acc+1}
                  end
               end
            in
               {TestLenLoc X 0}
            end
         end
      in
         % Chercher l'ensemble des mots possibles dans la database
         {InputText get(Words)}
         if {TestLen Words} == NG then
            WordsTree = {FindSubTree Words TreeDatabase} % Words are the two words that the users has written
            if WordsTree == nil then {OutputText set(1: nil|0|nil)}
            else
               % Chercher le meilleur nombre d'occurences et le total d'occurences
               BestAndTotal = {FindBestAndTotal WordsTree 0 0}
               if BestAndTotal.1 == 0 then {OutputText set(1: nil|0|nil)}
               else
                  % Structure de la réponse
                  Freq = {Int.toFloat BestAndTotal.1} / {Int.toFloat BestAndTotal.2.1}
                  Val = {FindWords BestAndTotal.1 WordsTree nil}
                  Ans = Val|Freq|nil
                  {OutputText set(1: Ans)}
               end
            end
         else {OutputText set(1: nil|0|nil)}
         end
      end
   end

   proc {PressHelper} % Procédure exécutée par les threads pour aider Press (pas le temps rip)
      Dummy = 0
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Read File and send words on BuffTail - 1 thread for each file exec
   % WordHead and WordTail are used to assemble caracs into words, as we read the file
   % Valid is 1 if there is at least 1 letter in the word
   proc {Read1File File BuffTail}
      local NewBuffTail TheChar in
         local
            proc {Manage Carac} 
               TheChar = Carac
               BuffTail = Carac|NewBuffTail 
            end
         in
            {File read(list:{Manage} size:1)}
            case TheChar of nil then skip
            else {Read1File File NewBuffTail}
            end
         end
      end
   end
   % Read File(s) and send on LocBuff - thread number imposed
   proc {ReadXFile N Total Folder Tail}
      Dummy = 0
   end

   % Parse CaracBuff : Rassembler les caractères récupérés sur CaracBuff en mots et les envoyer sur WordBuff
   proc {ParseCaracs CaracBuff Head Tail WordBuff}
      local NewHead NewTail NewWordBuff in
         local
            proc {Parse Carac}
               local
                  proc {Skip}
                     NewWordBuff = WordBuff
                     NewHead = Head
                     NewTail = Tail
                  end
                  proc {SendWord X}
                     Tail = nil
                     WordBuff = X|NewWordBuff
                     NewHead = NewTail
                  end
                  proc {SendEndWord X}
                     Tail = nil
                     WordBuff = X|"\n"|NewWordBuff
                     NewHead = NewTail
                  end
               in
                  % Signale une fin de phrase
                  case Carac of nil then {SendEndWord Head}
                  [] "!" then {SendEndWord Head}
                  [] "." then {SendEndWord Head}
                  [] "\n" then {SendEndWord Head}
                  
                  % Signale une fin de mot
                  [] " " then {SendWord Head}
                  [] "," then {SendWord Head}
                  
                  % A ignorer
                  [] "'" then {Skip}
                  [] "-" then {Skip}
                  
                  else % Ajouter la lettre au mot
                     NewHead = Head
                     Tail = Carac.1|NewTail
                     NewWordBuff = WordBuff
                  end
               end
            end
         in
            case CaracBuff
            of W|S2 then 
               case W of nil then {Parse W} NewWordBuff = nil
               else {Parse W} {ParseCaracs S2 NewHead NewTail NewWordBuff}
               end
            [] nil then skip end
         end
      end
   end

   % Parse WordBuff : Faire des listes de NG+1 mots en les envoyer sur le Port
   % Inputs :
   %     - WordBuff : Le buffer de mots à lire
   %     - Port : Le Port sur lequel envoyer les listes
   %     - 
   %     - 
   %     - 
   % Procédure pour chaque mot : 
   %     - L'ajoute à la première étape du WorkTree
   %     - Si Count est > NG, l'envoie prends le suivant comme future tête
   %     - L'ajoute aux étapes suivantes
   %     - Crée l'étape suivante avec le mot
   %
   %     => POUR ETAPES VISUELLES, VOIR Ngramme.oz !!
   %
   proc {ParseWords WordBuff Port WorkTree WorkTails Count}
      local NewWorkTree NewWorkTails NewTailsTail in
         local
            proc {Manage WordHead WordTail X Step}

               local NewWordTail NewTreeTail in
                  if Step == Count then % Ajouter l'étape suivante, puis si c'est le tout premier set NewWorkTree et NewWorkTree, sinon juste NewTailsTail
                     WordHead = (X|NewWordTail)|NewTreeTail
                     if Step == 0 then
                        WordTail = NewWordTail|NewTreeTail
                        NewWorkTree = WorkTree
                        NewWorkTails = WorkTails
                     else % Step == Count > 0, NewTailsTail a déjà été link à NewWorkTails !
                        NewTailsTail = NewWordTail|NewTreeTail
                     end

                  elseif Step == 0 then
                     if Count < NG then
                        % Si Count est < N (équilibre pas encore atteint), ajouter X mais garder le même NewWorkTree (et set NewWorkTails = NewWordTail|NewTailsTail)
                        WordTail.1 = X|NewWordTail
                        NewWorkTails = NewWordTail|NewTailsTail
                        
                        NewWorkTree = WorkTree
                        {Manage WordHead.2 WordTail.2 X Step+1}  
                     else
                        % Sinon ajouter X aussi et envoyer sur le Port, puis prends le suivant comme NewWorkTree
                        % Redéfinir NewWorkTails au fur et à mesure !!
                        WordTail.1 = X|nil
                        {Send Port WordHead.1}
                        NewWorkTree = WorkTree.2
                        {Manage WordHead.2 WorkTails.2 X Step+1}
                     end
                     
                  elseif Step == NG then % Ajouter l'étape suivante et c'est fini ! (Pareil que Step == Count > 0, mais chiant et inutile de bloquer Count à NG)
                     WordHead = (X|NewWordTail)|NewTreeTail
                     NewTailsTail = NewWordTail|NewTreeTail

                  else
                     % Sinon, ajouter X à l'étape suivante "normalement"
                     WordTail.1 = X|NewWordTail
                     NewWorkTails = NewWordTail|NewTailsTail

                     {Manage WordHead.2 WordTail.2 X Step+1}
                  end 
               end
            end
         in
            case WordBuff
            of H|T then
               case H of "\n" then % Fin de phrase
                  {ParseWords T Port NewWorkTree NewWorkTails 0}
               else
                  {Manage WorkTree WorkTails H 0}
                  {ParseWords T Port NewWorkTree NewWorkTails Count+1}
               end
            [] nil then {Send Port nil} % Fin d'exécution !
            end
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Lance les NbThreads threads de lecture et de parsing qui liront et traiteront tous les fichiers
   %%% Les threads de parsing envoient leur resultat au port Port
   proc {LaunchThreads Port NbThreads}
      local
         FoldName = {Append TweetsFolder "/"}
         % Execution si on veut 3 threads par file (1 pour lire, 2 pour parse)
         proc {FullLaunchThreads Folder}
            case Folder of nil then skip
            [] H|T then
               thread
                  local File Name CaracBuff WordBuff in

                     % Thread pour parser les infos (N-gramme)
                     thread local LocBuff in {ParseCaracs CaracBuff LocBuff LocBuff WordBuff} end end
                     thread local LocBuff2 LocTails2 in {ParseWords WordBuff Port LocBuff2 LocTails2 0} end end
                     
                     % Lit les fichiers !! (sous-fonction récursive pour CaracTail)
                     Name = {Append FoldName H}
                     File = {New Open.file init(name:{String.toAtom Name} flags:[read])}
                     local Empty in {Read1File File CaracBuff} end
                  end
               end
               {FullLaunchThreads T}
            end
         end
         % Execution pour un nombre de threads imposé
         proc {DefLaunchThreads Folder}
            {Browse 0}
         end
      in
         % Lancement de la procédure
         local Mid SourceFolder in
            Mid = NbThreads div 3
            SourceFolder = {OS.getDir TweetsFolder}
            case Mid of NFiles then {FullLaunchThreads SourceFolder} else {DefLaunchThreads SourceFolder} end
         end
      end
   end

   % Enregistre les N-gramme dans la database. Compte également le nombre de Threads qui ont terminé pour savoir quand s'arrêter
   % ATTENTION, valeur initiale de NilCount = 1 !!
   proc {SaveFromStream NbThreads TheTree TheStream NilCount}
      case TheStream of H|T then
         case H of nil then
            case NilCount of NbThreads then
               TreeDatabase = TheTree
            else {SaveFromStream TheTree T NilCount+1 NbThreads} end
         else
            local NewTree in
               % Enregistrer H dans TreeDatabase ! (Pour faire avec une liste : {SaveFromStream T NilCount NbThreads H|LocDatabase})
               NewTree = {InsertTrees TheTree H 0}
               {SaveFromStream NbThreads NewTree T NilCount}
            end
         end
      end
   end

   % Insert TheSeq in Tree :
   %     - Tree est la tête de l'arbre local
   %     - TheSeq = "AA"|"BB"|"CC"|nil, puis "BB"|"CC"|nil, ...
   %     - Index est l'index de l'élément en cours (si Index == NG, Tree est une liste !)
   fun {InsertTrees Tree Seq Index}
      % Insérer au bon endroit l'élem et passer au suivant
      local NewTree in
         case Tree of leaf then
            if Index == NG then % Si on en est au mot à deviner et qu'il n'existe pas
               tree(key:Seq.1 value:1 leaf leaf)
            else
               % Create the tree to add here, with as value a new tree with the next elem
               NewTree = {InsertTrees leaf Seq.2 Index+1}
               tree(key:Seq.1 value:NewTree leaf leaf)
            end

         [] tree(key:Y value:V T1 T2) andthen Seq.1 == Y then 
            % We found first word, thus we must insert in the second tree which is V
            NewTree = {InsertTrees V Seq.2 Index+1}
            tree(key:Y value:NewTree T1 T2)

         [] tree(key:Y value:V T1 T2) andthen {String.toAtom Seq.1} < {String.toAtom Y} then
            NewTree = {InsertTrees T1 Seq Index}
            tree(key: Y value:V NewTree T2)

         [] tree(key:Y value:V T1 T2) andthen {String.toAtom Seq.1} > {String.toAtom Y} then
            NewTree = {InsertTrees T2 Seq Index}
            tree(key: Y value:V T1 NewTree)
            
         [] A then Tree+1 % Si c'est une valeur numérique, c'est qu'on a trouvé le 3e mot et qu'on peut l'incrémenter !
         end
      end
   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Fetch Tweets Folder from CLI Arguments
   %%% See the Makefile for an example of how it is called
   fun {GetSentenceFolder}
      Args = {Application.getArgs record('folder'(single type:string optional:false))}
   in
      Args.'folder'
   end
   
   %%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
   proc {Main}
      local NbThreads SourceFolder Description Window SeparatedWordsStream SeparatedWordsPort in
         {Property.put print foo(width:1000 depth:1000)}  % for stdout siz
      
         % Creation de l'interface graphique
         Description=td(
            title: "Text predictor"
            lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action: proc {$} Y in Y = {Press} end))
            text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
            action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
         )
      
         % Creation de la fenetre
         Window={QTk.build Description}
         {Window show}
      
         {InputText tk(insert 'end' "Loading... Please wait.")}
         {InputText bind(event:"<Control-s>" action:Press)} % You can also bind events
      
         % Compter le nombre de fichiers
         TweetsFolder = {GetSentenceFolder}
         SourceFolder = {OS.getDir TweetsFolder}
         local
            fun {CountAllFiles LocFolder Acc}
               case LocFolder of nil then Acc
               [] H|T then  {CountAllFiles T Acc+1}
               end
            end
         in
            NFiles = {CountAllFiles SourceFolder 0}
         end

         % On lance les threads de lecture et de parsing, puis de création de la Database
         NbThreads = NFiles * 3
         SeparatedWordsPort = {NewPort SeparatedWordsStream}
         {LaunchThreads SeparatedWordsPort NbThreads}
         {SaveFromStream NbThreads leaf SeparatedWordsStream 1}
         {Browse 0}
      
         {InputText set(1:"")}
      end
      %%ENDOFCODE%%
   end
   % Appelle la procedure principale
   {Main}
end
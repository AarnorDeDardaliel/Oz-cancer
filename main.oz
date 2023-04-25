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
   Dummy % Variable for dev
   TreeDatabase % Variable Globale
   NFiles % Variable globale
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Pour ouvrir les fichiers
   class TextFile
      from Open.file Open.text
   end

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
      local Ans Val Freq in
         % TODO : Chercher la liste dans TreeDatabase
         % Etablir la réponse
         Val = nil % Liste des most probable words
         Freq = 0
         Ans = Val | Freq | nil
         Ans
      end
   end

   proc {PressHelper} % Procédure exécutée par chaque thread après l'initialisation (Useless pour le moment je pense. Pour les bonus ?)
      Dummy = 0
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Read Execution
   proc {Read From To Folder Tail}
      % TODO : Lit les fichiers et les mets dans LocBuff en remplaçant Tail
      % Quand a finit, mets un nil
      Dummy = 0
   end

   % Parse Execution
   proc {ParseBuffer Buffer Port}
      % Si le buffer n'est pas nil et a au moins 2 éléments, prendre le premier elem et le parse (le 2e est provisoire, et sera soit un elem soit nil)
      case Buffer of
      X|S2 then {Parse X Port} {ParseBuffer S2 Port}
      [] nil then skip end
   end
   proc {Parse Line Port}
      % TODO : Parse Line
      Dummy = 0
      % Envoie la rep sur le Port
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
   %%% Les threads de parsing envoient leur resultat au port Port
   proc {LaunchThreads Port N}
      local Mid in
         Mid = N div 2
         {RecLaunchThreads Mid Mid Port}
      end
   end
   proc {RecLaunchThreads N Total Port}
      case N of 0 then skip
      else
         thread 
            local LocBuf Tail Folder in
               % Thread pour parser les infos
               thread {ParseBuffer LocBuf Port} {PressHelper} end

               % Lit les fichiers !! (sous-fonction récursive pour Tail)
               Folder = {OS.getDir {GetSentenceFolder}}
               LocBuf = Tail
               {Read N Total Folder Tail}
            end
            {PressHelper}
         end
         {RecLaunchThreads N-1 Total Port}
      end
   end

   proc {SaveFromStream TheStream TreeDatabase NilCount NbThreads}
         case TheStream of H|T then
            case H of nil then
               NilCount = NilCount + 1
               case NilCount of NbThreads then skip else {SaveFromStream T TreeDatabase NilCount NbThreads} end
            else
               % TODO : Enregistrer H dans TreeDatabase !

               {SaveFromStream T TreeDatabase NilCount NbThreads}
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
      TweetsFolder = {GetSentenceFolder}
   in local NbThreads Folder InputText OutputText Description Window SeparatedWordsStream SeparatedWordsPort in
         {Property.put print foo(width:1000 depth:1000)}  % for stdout siz
      
         % Creation de l'interface graphique
         Description=td(
            title: "Text predictor"
            lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:Press))
            text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
            action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
         )
      
         % Creation de la fenetre
         Window={QTk.build Description}
         {Window show}
      
         {InputText tk(insert 'end' "Loading... Please wait.")}
         {InputText bind(event:"<Control-s>" action:Press)} % You can also bind events
      
         % Compter le nombre de fichiers
         Folder = {OS.getDir {GetSentenceFolder}}
         fun {CountAllFiles LocFolder Acc}
            case LocFolder of nil then Acc
            [] H|T then  {CountAllFiles T Acc+1}
            end
         end
         NFiles = {CountAllFiles Folder 0}

         % On lance les threads de lecture et de parsing, puis de création de la Database
         NbThreads = NFiles * 2
         SeparatedWordsPort = {NewPort SeparatedWordsStream}
         {LaunchThreads SeparatedWordsPort NbThreads}
         {SaveFromStream SeparatedWordsStream TreeDatabase 0 NbThreads}
      
         {InputText set(1:"")}
      end
   end
    % Appelle la procedure principale
   {Main}
end
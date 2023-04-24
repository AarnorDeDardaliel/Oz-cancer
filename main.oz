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
      local Ans in
         Ans = nil

         Ans
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Read Execution
   proc {Read N Total LocBuf Tail}
      % (TODO) Lit les fichiers (en se servant de N et Total pour savoir lesquels) et mets chaque ligne dans LocBuf
      % Quand a finit, mets une poison pill (un nil !)
      Dummy = 0
      % Utiliser ?
      %     case Folder of nil then skip
      %     [] H|T then {Browse {String.toAtom H}} {ListAllFiles T}
      %     end
      %  ?  ?  ?
   end

   % Parse Execution
   proc {ParseBuffer Buffer Port}
      % (DONE) Si le buffer n'est pas nil et a au moins 2 éléments, prendre le premier elem et le parse (le 2e est provisoire, et sera soit un elem soit nil)
      case Buffer of
      X|S2 then {Parse X Port} {ParseBuffer S2 Port}
      [] nil then skip end
   end
   proc {Parse Line Port}
      % TODO : Parse Line
      Dummy = 0
      % Envoie la rep sur le Port

   end
   fun {ParseLine Line}
      0
   end   

   % Launch Threads
   proc {LaunchRead N Total Port}
      case N of 0 then skip
      else
         thread 
            local LocBuf Tail Folder in
               thread {ParseBuffer LocBuf Port} end
               LocBuf = Tail
               % Lancer la lecture (TODO)
               Folder = {OS.getDir {GetSentenceFolder}}
               {Read N Total LocBuf Tail}
            end
         end
         {LaunchRead N-1 Total Port}
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
   %%% Les threads de parsing envoient leur resultat au port Port
   proc {LaunchThreads Port N}
      local Mid in
         Mid = N div 2
         {LaunchRead Mid Mid Port}
      end
   end

   proc {SaveFromStream TheStream FinalStruct NilCount NbThreads}
      case TheStream of H|T then
         case H of nil then
            NilCount = NilCount + 1
            case NilCount of NbThreads then skip else {SaveFromStream T FinalStruct NilCount NbThreads} end
         else
            % TODO : Enregistrer H => Utiliser un arbre ? (conseillé mais je vois pas le concept)

            {SaveFromStream T FinalStruct NilCount NbThreads}
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

   %%% Decomnentez moi si besoin
   %proc {ListAllFiles L}
   %   case L of nil then skip
   %   [] H|T then {Browse {String.toAtom H}} {ListAllFiles T}
   %   end
   %end
    
   %%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
   proc {Main}
      TweetsFolder = {GetSentenceFolder}
   in
      %% Fonction d'exemple qui liste tous les fichiers
      %% contenus dans le dossier passe en Argument.
      %% Inspirez vous en pour lire le contenu des fichiers
      %% se trouvant dans le dossier
      %%% N'appelez PAS cette fonction lors de la phase de
      %%% soumission !!!
      %{ListAllFiles {OS.getDir TweetsFolder}}
      %{Browse {OS.getDir TweetsFolder}}
       
      local NbThreads Folder InputText OutputText Description Window SeparatedWordsStream SeparatedWordsPort in
         {Property.put print foo(width:1000 depth:1000)}  % for stdout siz
         
         % TODO (je sais pas quoi)
      
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
      
         % On lance les threads de lecture et de parsing
         SeparatedWordsPort = {NewPort SeparatedWordsStream}
         NbThreads = 4 % DOIT ÊTRE PAIR !!
         {LaunchThreads SeparatedWordsPort NbThreads}

         % Lancer le thread de récupération
         local FinalStruct in 
            thread {SaveFromStream SeparatedWordsStream FinalStruct 0 NbThreads} end 
         end
      
         {InputText set(1:"")}
      end
   end
    % Appelle la procedure principale
   {Main}
end
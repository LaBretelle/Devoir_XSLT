<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei"
    version="2.0">
    <xsl:output method="text"/>
    
    <xsl:template match="TEI">
        <xsl:variable name="witfile">
            <xsl:value-of select="replace(base-uri(.), '.xml', '')"/>
            <!-- récupération du nom du fichier courant pour produire un fichier .tex avec le même nom que le fichier xml -->
        </xsl:variable>
        <xsl:result-document href="{concat($witfile, '.tex')}"> <!-- Je crée ici le schéma final de mon document dans lequel je vais insérer certaines
        parties grâce à des call-template, pour venir remplir la page de titre dans le préambule et le texte dans le corps. Ce fichier final prendra le nom stocké
        en variable, tout en ajoutant l'extension .tex -->
\documentclass[12pt, a4paper]{report}
\usepackage[utf8x]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{lmodern}
\usepackage{graphicx}
\usepackage[french]{babel}
\usepackage{reledmac}
\usepackage{glossaries}
\makeglossaries
<xsl:call-template name="glossaire"/> <!-- j'appelle le premier template qui liste les entrées de glossaire à mettre dans le préambule -->

\setstanzaindents{0,1}
\setcounter{stanzaindentsrepetition}{1}        
            
\Xarrangement[A]{paragraph}
\Xparafootsep{$\parallel$~}

<xsl:call-template name="titre"/> <!-- j'appelle ici les métadonnées de titre  -->

\begin{document}

\maketitle

\firstlinenum{5}
\linenumincrement{5}
\linenummargin{right}
\chapter*{Texte : vers <xsl:value-of select=".//sp[1]/l[1]/@n"/> au vers <xsl:value-of select=".//sp[last()]/l[last()]/@n"/>}  <!-- Grâceà du XPath, je viens récupérer
la valeur de l'attribut n du premier <l> et du dernier <l> de l'ensemble du document. Je spécifie que je veux la valeur de n du premier/dernier <l> du premier/dernier <sp> -->

\setline{<xsl:value-of select=".//sp[1]/l[1]/@n"/>} <!-- Je fais démarrer la numération là où démarre la numérotion dans l'attribut n du premier <l> du premier <sp> -->
\beginnumbering
\stanza 
<xsl:call-template name="texte"/> <!-- J'appelle le template contenant le texte -->
\endnumbering

\chapter*{Index} <!-- Je vais appeler mes deux index -->

\section*{Index des noms de personnes}
<xsl:call-template name="index_pers"/>
            
\section*{Index des noms de lieux}
<xsl:call-template name="index_lieux"/>
\printglossaries
\end{document}
        </xsl:result-document>
    </xsl:template>
            
    <xsl:template name="texte">
        <xsl:for-each select="//l"> <!-- Je boucle sur les <l> pour permettre de les compter. A chaque l j'ajoute à la fin un & (retour à la ligne sous LaTeX) et au 
        dernier <l> du document je fais terminer le vers par un \& qui met fin au document -->
            
            
            <xsl:choose>
                <xsl:when test="@part='I'"> <!-- Cette boucle permet de ne pas compter les vers scindés entre deux locuteurs -->
                    <xsl:text> \skipnumbering </xsl:text>
                </xsl:when>
            </xsl:choose>
            <!-- Dans cette boucle conditionnelle là, je compare la valeur du noeud parent <sp> de l'actuel <l> avec la valeur noeud parent <sp> du précédent <l>.
             Ainsi,je compare pour chaque vers si le locuteur, présent dans l'attribut @who, est le même. S'il est le même, on fait un saut de ligne.
            S'il est différent, alors on écrit le nom du locuteur (contenu dans l'attribut @who du noeud parent <sp>). -->
            <xsl:choose>
                <xsl:when test="parent::sp = preceding-sibling::l[1]/parent::sp">
                    <xsl:text> \qquad </xsl:text>
                    <xsl:apply-templates/>
                </xsl:when>
                <!-- preceding-sibling::l[1]/parent::sp  le " l[1] signifie que l'on prend uniquement le premier voisin précédent, et pas tous les précédents -->
                <xsl:otherwise>
                    <xsl:value-of select="parent::sp/replace(@who, '#','')"/>
                    <xsl:text> : </xsl:text>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- Dans cette seconde boucle conditionnelle, je compare la position du <l>. S'il est dernier, il faut rajouter un \& à la fin. Sinon, on met un & (saut de ligne) -->
            <xsl:choose>
                <xsl:when test="position() = last()">
                    <xsl:text> \&amp; </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text> &amp; </xsl:text>
                </xsl:otherwise>
            </xsl:choose> 
        </xsl:for-each> 
    </xsl:template>
   

    <!-- Je m'occupe ici de l'apparat critique. Pour chaque <app> (contenu dans <l>,  branche de l'arbre conservée), j'ajoute les balises d'apparat critique. A chaque
    variante (<rdg>), je mets la variante (value-of select=".") et l'acronyme de la variante (value-of select="(@wit, '#', ' '))-->
    <xsl:template match="app">
        <xsl:text>\edtext{</xsl:text>
        <xsl:choose>
            <xsl:when test="./lem/@type='om'">
                <xsl:text>\textit{omisit}</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:value-of select="lem"/><xsl:text>}{\Afootnote{</xsl:text>
        <xsl:for-each select="rdg">
            <xsl:choose>
                <xsl:when test="@type='om'">
                    <xsl:text>\textit{omisit} </xsl:text><xsl:value-of select="./replace(@wit, '#', ' ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/><xsl:text> </xsl:text>
                    <xsl:value-of select="./replace(@wit, '#', ' ')"/>
                </xsl:otherwise>
            </xsl:choose> <!-- S'il y a plus d'une variante, on met une virgule, et la boucle recommence avec la variante suivante -->
            <xsl:choose><xsl:when test="position() != last()">, </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>     
        </xsl:for-each>
        <xsl:text>}}</xsl:text>
    </xsl:template> 
    
    <!-- Je rajoute les métadonnées qui constitueront la page de titre -->
    <xsl:template name="titre">
        <xsl:text>\title{</xsl:text>
        <xsl:value-of select="//fileDesc/titleStmt/title[@xml:lang='FRA']"/> <!-- Je vais chercher le titre en français, puis le titre en latin grâce à l'attribut -->
        <xsl:text> \\ \textit{</xsl:text>
        <xsl:value-of select="//fileDesc/titleStmt/title[@xml:lang='LAT']"/>
        <xsl:text>}}\author{</xsl:text>
        <xsl:value-of select="//fileDesc/titleStmt/author"/> <!-- Seule le nom en français est dans le fileDesc : je le récupère -->
        <xsl:text>\\ \textit{</xsl:text>
        <xsl:element name="author">
            <xsl:value-of select="concat(//titleStmt/author/forename[@xml:lang='LAT'],' ', //titleStmt/author/name[@xml:lang='LAT'], ' ', //titleStmt/author/surname[@xml:lang='LAT'])"/> <!-- Je concatène les tria nomina de l'auteur -->
        </xsl:element>
        <xsl:text>}}</xsl:text>
        <xsl:text>\date{</xsl:text>
        <xsl:value-of select=".//date/@when"/>
        <xsl:text>}</xsl:text>
    </xsl:template>
    
    <!-- Je récupère dans le texte toutes les balises placeName et je les transforme en balise de glossaire LaTeX -->
    <xsl:template match="body//placeName">
        <xsl:text>\gls{</xsl:text>
        <!-- La formule ci-ddessous (réutilisée 3 autres fois) a pour but de récupérer le xml:id, et de mettre la première lettre en majuscule et les autres
        en minuscule. La formule réunit (avec concat) la première lettre du xml:id en la mettant en capitale (avec upper-case) et toutes les autres lettres en les mettant en 
        minuscule (avec lower-case) -->
        <xsl:value-of select="./concat(upper-case(substring(replace(@ref, '#', ''), 1, 1)), lower-case(substring(replace(@ref, '#', ''), 2)))"/>
        <xsl:text>}</xsl:text>
    </xsl:template>
    
    <!-- Je récupère dans le texte toutes les balises persName et je les transforme en balise de glossaire LaTeX -->
    <xsl:template match="persName">
        <xsl:text>\gls{</xsl:text>
        <xsl:value-of select="./concat(upper-case(substring(replace(@ref, '#', ''), 1, 1)), lower-case(substring(replace(@ref, '#', ''), 2)))"/>
        <xsl:text>}</xsl:text>
    </xsl:template>
    
    <!-- J'utilise la liste des lieux et des personnes du profileDesc pour compléter le glossaire dans le préambule LaTeX. -->
    <xsl:template name='glossaire'>
        <xsl:for-each select="//person">
            <xsl:text>\newglossaryentry{</xsl:text>
            <xsl:value-of select="./concat(upper-case(substring(replace(@xml:id, ' ', ''), 1, 1)), lower-case(substring(replace(@xml:id, ' ', ''), 2)))"/> <!-- Je récupère le xml:id pour nommer l'entité car je la récupère aussi pour compléter les balises
            \gls dans le texte. En effet, il faut que le nom dans le texte et dans le préambule soit identique, j'utilise donc la valeur de l'attribut xml:id / ref -->
            <xsl:text>}{name={</xsl:text>
            <xsl:value-of select="./concat(upper-case(substring(replace(@xml:id, ' ', ''), 1, 1)), lower-case(substring(replace(@xml:id, ' ', ''), 2)))"/> 
            <xsl:text>},description={</xsl:text>
            <xsl:value-of select="./occupation/text()"/> <!-- Ce qui est écrit dans la balise <occupation> est ce qui se rapproche le plus d'une note de glossaire -->
            <xsl:text>}}</xsl:text>
        </xsl:for-each>
        <!-- Je fais la même chose à l'identique, mais pour les lieux -->
        <xsl:for-each select="//place">
            <xsl:text>\newglossaryentry{</xsl:text>
            <xsl:value-of select="./concat(upper-case(substring(replace(@xml:id, ' ', ''), 1, 1)), lower-case(substring(replace(@xml:id, ' ', ''), 2)))"/>
            <xsl:text>}{name={</xsl:text>
            <xsl:value-of select="./concat(upper-case(substring(replace(@xml:id, ' ', ''), 1, 1)), lower-case(substring(replace(@xml:id, ' ', ''), 2)))"/>
            <xsl:text>},description={</xsl:text>
            <xsl:value-of select="./note/text()"/>
            <xsl:text>}}</xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Le fonctionnement de l'index des personnes et des lieux est identique. Je crée une boucle qui sélectionne toutes les balises <persName> du <body>
    (il y a des balises <persName> dans le Header, il ne faut pas les prendre), et je prends le texte à l'intérieur de la balise. Ce texte est mis en gras.
    Ensuite, je cherche à récupérer le nom français de ce que j'ai sélectionné. Pour cela, je donne à une variable (ici $attribut_pers) la valeur de l'attribut @ref de
    la balise <persName>, que j'insère ensuite dans un chemin Xpath permettant de récupérer dans le Header la version décrite du mot. Cela permet d'avoir
    l'occurence du mot dans le texte, puis une forme canonique que j'ai décrété dans le Header. Enfin, je récupère le numéro du vers en récupérant la valeur de 
    l'attribut @n du <l> parent (plus précisément ancêtre, car généralement il y a d'autres balises entre <persName> et <l>). -->
    <xsl:template name="index_pers">
        <xsl:for-each select="//body//persName">
            <xsl:text>\textbf{</xsl:text>
            <xsl:value-of select="./text()"/> <!-- Je sélectionne la valeur de texte à l'intérieur du <persName> -->
            <xsl:text>} : </xsl:text>
            <xsl:text>\textit{</xsl:text>
            <xsl:variable name="attribut_pers">
                <xsl:value-of select="./replace(@ref, '#', '')"/> <!-- j'attribue à une variable la valeur de l'attribut @ref -->
            </xsl:variable>
            <xsl:value-of select="//person[@xml:id=$attribut_pers]//surname"/> <!-- J'insère dans mon Xpath ma variable pour sélectionner le bon <surname> -->
            <xsl:text>}, v.</xsl:text>
            <xsl:value-of select="ancestor::l/@n"/> <!-- Je récupère la valeur de l'attribut @n pour numéroter mon verss -->
            <xsl:text> \\ </xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="index_lieux">
        <xsl:for-each select="//body//placeName">
            <xsl:text>\textbf{</xsl:text>
            <xsl:value-of select="./text()"/>
            <xsl:text>} : </xsl:text>
            <xsl:text>\textit{</xsl:text>
            <xsl:variable name="attribut_lieu">
                <xsl:value-of select="./replace(@ref, '#', '')"/>
            </xsl:variable>
            <xsl:value-of select="//place[@xml:id=$attribut_lieu]/placeName"/>
            <xsl:text>}, v.</xsl:text>
            <xsl:value-of select="ancestor::l/@n"/>
            <xsl:text> \\ </xsl:text>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>
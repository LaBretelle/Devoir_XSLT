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
\chapter{texte : vers <xsl:value-of select=".//sp[1]/l[1]/@n"/> au vers <xsl:value-of select=".//sp[last()]/l[last()]/@n"/>}  <!-- Grâceà du XPath, je viens récupérer
la valeur de l'attribut n du premier <l> et du dernier <l> de l'ensemble du document. Je spécifie que je veux la valeur de n du premier/dernier <l> du premier/dernier <sp> -->

\setline{<xsl:value-of select=".//sp[1]/l[1]/@n"/>} <!-- Je fais démarrer la numération là où démarre la numérotion dans l'attribut n du premier <l> du premier <sp> -->
\beginnumbering
\stanza 
<xsl:call-template name="texte"/> <!-- J'appelle le template contenant le texte -->
\endnumbering
\printglossaries
\end{document}
        </xsl:result-document>
    </xsl:template>
            
    <xsl:template name="texte">
        <xsl:for-each select="//l"> <!-- Je boucle sur les <l> pour permettre de les compter. A chaque l j'ajoute à la fin un & (retour à la ligne sous LaTeX) et au 
        dernier <l> du document je fais terminer le vers par un \& qui met fin au document -->
            
            <!-- Dans cette boucle conditionnelle là, je compare la valeur de l'attribut @who du noeud parent <sp> de l'actuel <l> avec la valeur de l'attribut @who
              du noeud parent <sp> du précédent <l>. Ainsi,je compare pour chaque vers si le locuteur est le même. S'il est le même, on fait un saut de ligne.
            S'il est différent, alors on écrit le nom du locuteur (contenu dans l'attribut @who du noeud parent <sp>). -->
            <xsl:choose>
                <xsl:when test="parent::sp = preceding-sibling::l[1]/parent::sp"><xsl:text> \qquad </xsl:text><xsl:apply-templates/></xsl:when>
                <!-- preceding-sibling::l[1]/parent::sp  le " l[1] signifie que l'on prend uniquement le premier voisin précédent, et pas tous les précédents -->
                <xsl:otherwise><xsl:value-of select="parent::sp/replace(@who, '#','')"/>
                    <xsl:text> : </xsl:text>
                    <xsl:apply-templates/></xsl:otherwise>
            </xsl:choose>
            <!-- Dans cette seconde boucle conditionnelle, je compare la position du <l>. S'il est dernier, il faut rajouter un \& à la fin. Sinon, on met un & (saut de ligne) -->
            <xsl:choose>
                <xsl:when test="position() = last()"><xsl:text> \&amp; </xsl:text></xsl:when>
                <xsl:otherwise><xsl:text> &amp; </xsl:text></xsl:otherwise>
            </xsl:choose> 
        </xsl:for-each> 
    </xsl:template>
   

    <!-- Je m'occupe ici de l'apparat critique. Pour chaque <app> (contenu dans <l>,  branche de l'arbre conservée), j'ajoute les balises d'apparat critique. A chaque
    variante (<rdg>), je mets la variante (value-of select=".") et l'acronyme de la variante (value-of select="(@wit, '#', ' '))-->
    <xsl:template match="app">
        <xsl:text>\edtext{</xsl:text>
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
        <xsl:value-of select="./replace(@ref, '#', '')"/>
        <xsl:text>}</xsl:text>
    </xsl:template>
    
    <!-- Je récupère dans le texte toutes les balises persName et je les transforme en balise de glossaire LaTeX -->
    <xsl:template match="persName">
        <xsl:text>\gls{</xsl:text>
        <xsl:value-of select="./replace(@ref, '#', '')"/>
        <xsl:text>}</xsl:text>
    </xsl:template>
    
    <!-- J'utilise la liste des lieux et des personnes du profileDesc pour compléter le glossaire dans le préambule LaTeX. -->
    <xsl:template name='glossaire'>
        <xsl:for-each select="//person">
            <xsl:text>\newglossaryentry{</xsl:text>
            <xsl:value-of select="./replace(@xml:id, ' ', '')"/> <!-- Je récupère le xml:id pour nommer l'entité car je la récupère aussi pour compléter les balises
            \gls dans le texte. En effet, il faut que le nom dans le texte et dans le préambule soit identique, j'utilise donc la valeur de l'attribut xml:id / ref -->
            <xsl:text>}{name={</xsl:text>
            <xsl:value-of select="./replace(@xml:id, ' ', '')"/> 
            <xsl:text>},description={</xsl:text>
            <xsl:value-of select="./occupation/text()"/> <!-- Ce qui est écrit dans la balise <occupation> est ce qui se rapproche le plus d'une note de glossaire -->
            <xsl:text>}}</xsl:text>
        </xsl:for-each>
        <!-- Je fais la même chose à l'identique, mais pour les lieux -->
        <xsl:for-each select="//place">
            <xsl:text>\newglossaryentry{</xsl:text>
            <xsl:value-of select="./replace(@xml:id, ' ', '')"/>
            <xsl:text>}{name={</xsl:text>
            <xsl:value-of select="./replace(@xml:id, ' ', '')"/>
            <xsl:text>},description={</xsl:text>
            <xsl:value-of select="./note/text()"/>
            <xsl:text>}}</xsl:text>
        </xsl:for-each>
    </xsl:template>
    

    
</xsl:stylesheet>
xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: Create the list of tei:respStmt :)
declare function local:create_respStmts() {
  (: Let's create a list of people unifying forename and surname with a "|" :)
  let $people :=
    for $object in collection("/db/apps/app-documentidamore/data")//tei:TEI
    return concat($object//tei:respStmt//tei:forename, "|",
                  $object//tei:respStmt//tei:surname)

  (: Let's remove the duplicate :)
  let $distinctPeople := distinct-values($people)
  return

    (: For each one... :)
    for $person in $distinctPeople
    return

      (: Let's split the name again :)
      let $forename := substring-before($person, "|")
      let $surname := substring-after($person, "|")
      return

        (: Finally, a tei:respStmt :)
        element tei:respStmt {
          element tei:resp { "Responsabile della codifica" },
          element tei:persName {
            element tei:forename { $forename },
            element tei:surname { $surname }
          }
        }
};

(: Gets the list of surfaces from the files :)
declare function local:create_surfaces() {
    for $object in collection("/db/apps/app-documentidamore/data")//tei:TEI
    return $object//tei:facsimile/tei:surface
};

(: Let's create the final TEI document :)
element tei:TEI {

  (: Here the tei header :)
  element tei:teiHeader {
    element tei:fileDesc {
      element tei:titleStmt {
        element tei:title { "Documenti d'Amore" },

        (: The list of persons is taken from the files :)
        local:create_respStmts()
      },

      element tei:publicationStmt {
        element tei:p {}
      },

      element tei:sourceDesc {
        element tei:p {}
      }
    }
  },

  (: Surfaces :)
  element tei:facsimile {
    local:create_surfaces()
  },

  (: Here the text :)
  element tei:text {
    (: TODO :)
  }
}
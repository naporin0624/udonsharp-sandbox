using TMPro;
using UnityEngine;

public class DisplayCurrentCount : Observer 
{
    [SerializeField]
    private Store store;

    private TextMeshProUGUI displayText
    {
        get
        {
            return gameObject.GetComponent<TextMeshProUGUI>();
        }
    }

    public override void OnNotify()
    {
        displayText.text = store.count.ToString();
    }
}

